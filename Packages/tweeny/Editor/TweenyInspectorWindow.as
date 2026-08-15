using namespace CometEngine;
using namespace CometEditor;

namespace Tweeny
{
  /// <summary>
  /// Shows what Tweeny is animating, and lets it be driven by hand.
  ///
  /// The window has two jobs because there are two things worth looking at. Out of play mode there are no
  /// tweens at all -- nothing has run yet -- so it lists the TweenyAnimation components sitting in the open
  /// scene and previews them in place, which is the whole point of a preview: seeing the animation without
  /// pressing Play. In play mode it switches to the live tween list, where the interesting thing is what is
  /// actually running right now, with its progress and its controls.
  /// </summary>
  [MainMenuItemWindow("Tweeny/Tweeny Inspector", "Tweeny Inspector")] class TweenyInspectorWindow : EditorWindow
  {
    private int selected = -1;

    /// The components found in the open scenes, rebuilt each frame so the list never goes stale.
    private array<TweenyAnimation@> animations;
    private array<Entity@> animationOwners;

    /// Distance the editor leaves between a property widget and the right edge of the window. Matching it
    /// is what lines the toolbar up with the fields underneath.
    private float WIDGET_RIGHT_MARGIN = 15.0f;

    CometEditor::WindowConfig OnGetWindowConfig()
    {
      CometEditor::WindowConfig config;
      config.initialSize = Vector2i(780, 440);
      config.initialPositionType = CometEditor::WindowConfigPositionType::CENTERED;
      config.iconRaw = CometEditor::RawIcon::SlidersH;
      return config;
    }

    void OnGUI()
    {
      bool playing = CometEditor::EditorApplication::IsPlaying();
      Tweeny::PreviewSession().SetPlayMode(playing);
      if (!playing)
      {
        CollectAnimations();
      }

      DrawHeader(playing);
      DrawPreviewSection(playing);

      if (playing)
      {
        DrawTweenTable();
      }
      else
      {
        DrawAnimationTable();
      }

      if (Tweeny::PreviewSession().Advance())
      {
        CometEditor::EditorApplication::RequestSceneRedraw();
      }
    }

    // ---- header --------------------------------------------------------------------------------------

    /// <summary>
    /// The window's toolbar: the same four buttons in both modes, right-aligned so the row ends exactly where
    /// the property widgets below it do.
    ///
    /// Out of play mode they drive the preview session; in play mode they drive the tweens the running game
    /// has made. Killing is the one that only means something in play mode, because out of it Stop already
    /// ends a preview outright. Anything pressed here changes the world, so the viewports are marked stale --
    /// otherwise stopping would restore the values and the scene would keep showing the animated ones until
    /// something else happened to redraw it.
    /// </summary>
    /// <param name="playing">Whether the editor is in play mode.</param>
    private void DrawHeader(bool playing)
    {
      GUI::Spacing();
      GUI::SetCursorAtStandardFieldPosition();
      GUI::AlignTextToFramePadding();
      if (playing)
      {
        int total = Tweeny::TotalActiveTweens();
        GUI::Text(total + (total == 1 ? " tween" : " tweens"));
        GUI::SameLine();
        GUI::TextDisabled("(" + Tweeny::TotalPlayingTweens() + " playing)");
      }

      float size = TweenyEditorStyle::BUTTON_SIZE;
      float rightEdge = GUI::GetWindowSize().x - WIDGET_RIGHT_MARGIN;
      float start = rightEdge - TweenyEditorStyle::RowWidth(4, size);
      if (start > GUI::GetCursorPosX())
      {
        GUI::SameLine(start);
      }
      else
      {
        GUI::SameLine();
      }

      TweenyPreviewSession@ session = Tweeny::PreviewSession();

      bool running = playing ?(Tweeny::TotalPlayingTweens() > 0) : session.IsPreviewing();
      bool held = playing
      ?(Tweeny::TotalActiveTweens() > 0 && Tweeny::TotalPlayingTweens() == 0)
      : session.IsPaused();
      bool canStart = playing ?(Tweeny::TotalActiveTweens() > 0) :(animations.length() > 0);
      bool acted = false;

      TweenyEditorStyle::BeginButtonRow();

      GUI::BeginDisabled(!canStart && !running);
      if (TweenyEditorStyle::RowButton(
      running ? CometEditor::RawIcon::Redo : CometEditor::RawIcon::Play, size, false,
      running ? "Start everything again from the beginning" : "Play everything"))
      {
        if (playing && running)
        {
          Tweeny::RestartAll(true);
        }
        else if (playing)
        {
          Tweeny::PlayAll();
        }
        else if (running)
        {
          session.Restart();
        }
        else
        {
          session.PlayAll(animations);
        }
        acted = true;
      }
      GUI::EndDisabled();

      TweenyEditorStyle::JoinNext();
      GUI::BeginDisabled(!running && !held);
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Pause, size, held,
      held ? "Resume everything" : "Pause everything"))
      {
        if (playing)
        {
          Tweeny::TogglePauseAll();
        }
        else
        {
          session.TogglePause();
        }
        acted = true;
      }
      GUI::EndDisabled();

      TweenyEditorStyle::JoinNext();
      GUI::BeginDisabled(!running && !held);
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Stop, size, false,
      playing ? "Rewind everything and pause" : "Stop the preview and put everything back"))
      {
        if (playing)
        {
          Tweeny::RewindAll(true);
        }
        else
        {
          session.Stop();
        }
        acted = true;
      }
      GUI::EndDisabled();

      TweenyEditorStyle::JoinNext();
      GUI::BeginDisabled(!playing || Tweeny::TotalActiveTweens() == 0);
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Trash, size, false, "Kill every tween"))
      {
        Tweeny::KillAll(false);
        acted = true;
      }
      GUI::EndDisabled();

      TweenyEditorStyle::EndButtonRow();

      if (acted)
      {
        CometEditor::EditorApplication::RequestSceneRedraw();
      }
    }

    // ---- preview -------------------------------------------------------------------------------------

    private void DrawPreviewSection(bool playing)
    {
      GUI::SeparatorText("Preview");

      TweenyPreviewSession@ session = Tweeny::PreviewSession();
      bool edited = false;

      GUI::StandardFieldName("Preview speed",
      "Drives the preview here, and Tweeny's global time scale, so it slows the running scene too.");
      GUI::SetCursorAtStandardPropertyWidgetPosition();
      GUI::SetNextItemWidthToStandardPropertyWidget();
      float speed = GUI::SliderFloat("##speed", session.GetSpeed(), 0.05f, 4.0f, edited);
      if (edited)
      {
        session.SetSpeed(speed);
        Tweeny::SetTimeScale(speed);
      }

      if (playing)
      {
        GUI::BeginDisabled(Tweeny::TotalActiveTweens() == 0);
        GUI::SetCursorAtStandardFieldPosition();
        if (GUI::Button(CometEditor::RawIcon::Eye + "  Drive every live tween by hand"))
        {
          session.PlayLive(Tweeny::AllTweens());
        }
        GUI::Tooltip("Takes the running tweens off the game clock and onto this window's.");
        GUI::EndDisabled();
      }
    }

    // ---- the scene's animation components ------------------------------------------------------------

    /// <summary>
    /// Finds every TweenyAnimation in every open scene.
    ///
    /// There is no lookup by component type in the scripting API, so the scenes are walked. Every loaded
    /// scene is visited rather than just the active one, because scenes open additively and an animation
    /// in one of the others is still on screen. The list is rebuilt each frame rather than cached: the
    /// user can delete an entity from the Hierarchy between two frames, and a stale handle would outlive
    /// it. That costs nothing while nobody is looking, because the editor only draws when asked to.
    /// </summary>
    private void CollectAnimations()
    {
      animations.resize(0);
      animationOwners.resize(0);

      int sceneCount = CometEngine::SceneManagement::SceneManager::GetScenesLoadedCount();
      for (int s = 0; s < sceneCount; s++)
      {
        CometEngine::SceneManagement::Scene scene =
        CometEngine::SceneManagement::SceneManager::GetSceneLoadedAt(s);
        if (!scene.IsValid() || !scene.IsLoaded())
        {
          continue;
        }

        array<Entity@>@ roots = CometEngine::SceneManagement::Scene::GetRoots(scene);
        if (roots is null)
        {
          continue;
        }
        for (uint i = 0; i < roots.length(); i++)
        {
          CollectFrom(roots[i]);
        }
      }
    }

    private void CollectFrom(Entity@ entity)
    {
      if (entity is null)
      {
        return;
      }

      array<TweenyAnimation@>@ here = TweenyAnimation::GetAll(entity);
      if (here !is null)
      {
        for (uint i = 0; i < here.length(); i++)
        {
          if (here[i] is null || AlreadyListed(here[i]))
          {
            continue;
          }
          animations.insertLast(here[i]);
          animationOwners.insertLast(entity);
        }
      }

      for (int i = 0; i < entity.childrenSize; i++)
      {
        CollectFrom(entity.GetChild(i));
      }
    }

    /// <summary>
    /// Whether a component is already in the list.
    ///
    /// The same entity can be reached more than once -- a scene can appear in the loaded list under more
    /// than one index, and an entity can be walked from two roots -- and each of those would put the same
    /// component in the table twice. Matching on the instance id settles it whatever the route was.
    /// </summary>
    /// <param name="animation">The component about to be added.</param>
    /// <returns>Returns true when it is already listed.</returns>
    private bool AlreadyListed(TweenyAnimation@ animation)
    {
      for (uint i = 0; i < animations.length(); i++)
      {
        if (animations[i] !is null && animations[i].instanceID == animation.instanceID)
        {
          return true;
        }
      }
      return false;
    }

    private void DrawAnimationTable()
    {
      GUI::SeparatorText("Animations in the scene");

      if (animations.length() == 0)
      {
        GUI::TextDisabled("No entity in this scene has a TweenyAnimation component.");
        return;
      }

      int flags = GUI::TableFlags::RowBg | GUI::TableFlags::BordersInnerV
      | GUI::TableFlags::BordersOuter | GUI::TableFlags::ScrollY
      | GUI::TableFlags::Resizable | GUI::TableFlags::SizingStretchProp;
      if (!GUI::BeginTable("animations", 6, flags))
      {
        return;
      }

      GUI::TableSetupScrollFreeze(0, 1);
      GUI::TableSetupColumn("Entity", GUI::TableColumnFlags::WidthStretch, 2.0f);
      GUI::TableSetupColumn("Animates", GUI::TableColumnFlags::WidthStretch, 1.4f);
      GUI::TableSetupColumn("Progress", GUI::TableColumnFlags::WidthStretch, 1.6f);
      GUI::TableSetupColumn("Duration", GUI::TableColumnFlags::WidthFixed, 80.0f);
      GUI::TableSetupColumn("Loops", GUI::TableColumnFlags::WidthFixed, 70.0f);
      GUI::TableSetupColumn("Controls",
      GUI::TableColumnFlags::WidthFixed | GUI::TableColumnFlags::NoResize
      | GUI::TableColumnFlags::NoReorder,
      TweenyEditorStyle::ControlsColumnWidth(3, GUI::GetFrameHeight()));
      GUI::TableHeadersRow();

      for (uint i = 0; i < animations.length(); i++)
      {
        DrawAnimationRow(int(i), animations[i], animationOwners[i]);
      }

      GUI::EndTable();
    }

    private void DrawAnimationRow(int index, TweenyAnimation@ animation, Entity@ owner)
    {
      if (animation is null)
      {
        return;
      }
      GUI::TableNextRow();
      GUI::PushIDNum(index);

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      DrawEntityLink(owner);

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      GUI::Text(AnimationTypeName(animation.animationType));

      GUI::TableNextColumn();
      DrawAnimationProgress(animation);

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      GUI::Text(formatFloat(animation.duration, "", 0, 2) + "s");

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      GUI::Text(animation.loops == -1 ? CometEditor::RawIcon::Infinity : "" + animation.loops);

      GUI::TableNextColumn();
      DrawAnimationRowActions(animation);

      GUI::PopID();
    }

    /// <summary>
    /// How far through its loop this row's animation is, or an empty bar when it is not previewing.
    /// </summary>
    /// <param name="animation">The animation on this row.</param>
    private void DrawAnimationProgress(TweenyAnimation@ animation)
    {
      TweenyPreviewSession@ session = Tweeny::PreviewSession();
      if (!session.IsPreviewing(animation))
      {
        TweenyEditorStyle::ProgressBar(0.0f, "Not previewing");
        return;
      }

      float fraction = session.GetProgress(animation);
      TweenyEditorStyle::ProgressBar(fraction,
      formatFloat(fraction * animation.duration, "", 0, 2) + "s of "
      + formatFloat(animation.duration, "", 0, 2) + "s this loop");
    }

    /// <summary>
    /// The per-row transport, the same three buttons the live tween list carries.
    ///
    /// A row is one animation, so these act on that one alone: they start it, hold it and put it back
    /// without touching anything else that happens to be previewing. They keep the frame height rather than
    /// the toolbar size, because a taller button would stretch every row of the table.
    /// </summary>
    /// <param name="animation">The animation on this row.</param>
    private void DrawAnimationRowActions(TweenyAnimation@ animation)
    {
      TweenyPreviewSession@ session = Tweeny::PreviewSession();
      bool running = session.IsPreviewing(animation);
      bool held = running && session.IsPaused();
      float size = GUI::GetFrameHeight();
      bool acted = false;

      TweenyEditorStyle::CenterButtonRow(3, size);

      TweenyEditorStyle::BeginButtonRow();

      if (TweenyEditorStyle::RowButton(
      running ? CometEditor::RawIcon::Redo : CometEditor::RawIcon::Play, size, false,
      running ? "Play it again from the start" : "Preview this one"))
      {
        session.Play(animation);
        acted = true;
      }

      TweenyEditorStyle::JoinNext();
      GUI::BeginDisabled(!running);

      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Pause, size, held, held ? "Resume" : "Pause"))
      {
        session.TogglePause();
        acted = true;
      }

      TweenyEditorStyle::JoinNext();
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Stop, size, false,
      "Stop this one and put it back"))
      {
        session.StopFor(animation);
        acted = true;
      }

      GUI::EndDisabled();
      TweenyEditorStyle::EndButtonRow();

      if (acted)
      {
        CometEditor::EditorApplication::RequestSceneRedraw();
      }
    }

    private string AnimationTypeName(TweenyAnimationType kind)
    {
      switch (kind)
      {
        case TweenyAnimationType::Move: return "Move";
        case TweenyAnimationType::LocalMove: return "Local move";
        case TweenyAnimationType::Scale: return "Scale";
        case TweenyAnimationType::Rotate: return "Rotate";
        case TweenyAnimationType::Fade: return "Fade";
        case TweenyAnimationType::Tint: return "Tint";
        case TweenyAnimationType::PunchPosition: return "Punch position";
        case TweenyAnimationType::PunchScale: return "Punch scale";
        case TweenyAnimationType::ShakePosition: return "Shake position";
        case TweenyAnimationType::ShakeScale: return "Shake scale";
      }
      return "Move";
    }

    // ---- the live tween list -------------------------------------------------------------------------

    private void DrawTweenTable()
    {
      GUI::SeparatorText("Active tweens");

      array<ITween@>@ tweens = Tweeny::AllTweens();
      if (tweens.length() == 0)
      {
        GUI::TextDisabled("Nothing is tweening right now.");
        return;
      }

      int flags = GUI::TableFlags::RowBg | GUI::TableFlags::BordersInnerV
      | GUI::TableFlags::BordersOuter | GUI::TableFlags::ScrollY
      | GUI::TableFlags::Resizable | GUI::TableFlags::SizingStretchProp;
      if (!GUI::BeginTable("tweens", 6, flags))
      {
        return;
      }

      GUI::TableSetupScrollFreeze(0, 1);
      GUI::TableSetupColumn("Tween", GUI::TableColumnFlags::WidthStretch, 2.0f);
      GUI::TableSetupColumn("Target", GUI::TableColumnFlags::WidthStretch, 1.6f);
      GUI::TableSetupColumn("Progress", GUI::TableColumnFlags::WidthStretch, 1.6f);
      GUI::TableSetupColumn("Loops", GUI::TableColumnFlags::WidthFixed, 70.0f);
      GUI::TableSetupColumn("State", GUI::TableColumnFlags::WidthFixed, 80.0f);
      GUI::TableSetupColumn("Controls",
      GUI::TableColumnFlags::WidthFixed | GUI::TableColumnFlags::NoResize
      | GUI::TableColumnFlags::NoReorder,
      TweenyEditorStyle::ControlsColumnWidth(4, GUI::GetFrameHeight()));
      GUI::TableHeadersRow();

      for (uint i = 0; i < tweens.length(); i++)
      {
        ITween@ tween = tweens[i];
        if (tween is null)
        {
          continue;
        }
        DrawRow(int(i), tween);
      }

      GUI::EndTable();

      if (selected >= 0 && selected < int(tweens.length()))
      {
        DrawDetails(tweens[uint(selected)]);
      }
    }

    private void DrawRow(int index, ITween@ tween)
    {
      GUI::TableNextRow();
      GUI::PushIDNum(index);

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      if (GUI::Selectable(NameOf(index, tween), selected == index,
      GUI::SelectableFlags::SpanAllColumns | GUI::SelectableFlags::AllowOverlap))
      {
        selected = index;
      }

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      DrawEntityLink(EntityOf(tween), index);

      GUI::TableNextColumn();
      DrawProgress(tween);

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      int loops = tween.GetLoops();
      GUI::Text(loops == -1
      ?(tween.GetCompletedLoops() + " / " + CometEditor::RawIcon::Infinity)
      :(tween.GetCompletedLoops() + " / " + loops));

      GUI::TableNextColumn();
      GUI::AlignTextToFramePadding();
      DrawState(tween);

      GUI::TableNextColumn();
      DrawRowActions(tween);

      GUI::PopID();
    }

    /// <summary>
    /// The entity a tween is animating, as a link that selects it.
    ///
    /// A tween's target is a component, not an entity, and a component carries no name of its own -- which
    /// is why printing the target's name gave a blank column. What is useful is the entity it belongs to,
    /// and being able to click it and have the hierarchy jump there.
    /// </summary>
    /// <param name="entity">The entity to show, or null.</param>
    private void DrawEntityLink(Entity@ entity, int row = -1)
    {
      if (entity is null || !Object::IsValid(entity))
      {
        GUI::TextDisabled("--");
        return;
      }
      if (GUI::Selectable(entity.name, false))
      {
        FocusInHierarchy(entity);
        if (row >= 0)
        {
          selected = row;
        }
      }
      GUI::Tooltip("Select this entity");
    }

    /// <summary>
    /// Selects an entity and reveals it in the Hierarchy: expands its parents, scrolls its row into view
    /// and flashes it.
    ///
    /// Selecting on its own is not enough. It only marks the entity, so a row collapsed inside a parent or
    /// scrolled off the end of a long list shows nothing at all and the click looks like it did nothing.
    ///
    /// The reveal goes through the editor's bridge function rather than a namespaced wrapper because the
    /// wrappers live in the internal script module, which the editor loads from bytecode compiled into the
    /// executable. The bridge functions are registered when the editor starts, so this resolves against the
    /// engine that is actually running.
    /// </summary>
    /// <param name="entity">The entity to select and reveal.</param>
    private void FocusInHierarchy(Entity@ entity)
    {
      CometEditor::Selection::Set(entity);
      __Selection__Ping(entity);
    }

    /// <summary>
    /// Resolves a tween's target to the entity that owns it.
    /// </summary>
    /// <param name="tween">The tween to inspect.</param>
    /// <returns>Returns the entity, or null when the target is gone or is not a component.</returns>
    private Entity@ EntityOf(ITween@ tween)
    {
      Object@ target = tween.GetTarget();
      if (target is null || !Object::IsValid(target))
      {
        return null;
      }
      Behaviour@ behaviour = cast<Behaviour@>(target);
      if (behaviour !is null)
      {
        return behaviour.entity;
      }
      return cast<Entity@>(target);
    }

    /// <summary>
    /// How far a live tween is through its current loop.
    ///
    /// The bar tracks the loop rather than the whole run: against the full duration a looping tween barely
    /// creeps and an endless one never moves at all, while against the loop it sweeps and starts over each
    /// cycle, which is what the tween is doing.
    /// </summary>
    /// <param name="tween">The tween on this row.</param>
    private void DrawProgress(ITween@ tween)
    {
      float duration = tween.GetDuration();
      float fraction = duration <= 0.0f ? 0.0f : tween.GetPosition() / duration;
      float full = tween.GetFullDuration(true);
      float elapsed = tween.GetElapsed(true);

      TweenyEditorStyle::ProgressBar(fraction,
      formatFloat(tween.GetPosition(), "", 0, 2) + "s of "
      + formatFloat(duration, "", 0, 2) + "s this loop, "
      + formatFloat(elapsed, "", 0, 2) + "s in total"
      + (tween.GetLoops() == -1 ? " (endless)" : " of " + formatFloat(full, "", 0, 2) + "s"));
    }

    private void DrawState(ITween@ tween)
    {
      if (tween.IsComplete())
      {
        GUI::TextDisabled("complete");
        return;
      }
      if (!tween.IsPlaying())
      {
        GUI::TextDisabled("paused");
        return;
      }
      GUI::TextColored(GUI::GetStyleColor(GUI::Col::CheckMark),
      tween.IsBackwards() ? "backwards" : "playing");
    }

    /// <summary>
    /// The per-row transport for a live tween.
    ///
    /// Stop here means rewind and pause, which is what stopping an animation means: back to the start and not
    /// playing. Killing is the separate, destructive one.
    /// </summary>
    /// <param name="tween">The tween on this row.</param>
    private void DrawRowActions(ITween@ tween)
    {
      float size = GUI::GetFrameHeight();
      bool held = tween.IsActive() && !tween.IsPlaying() && !tween.IsComplete();
      bool acted = false;

      TweenyEditorStyle::CenterButtonRow(4, size);
      TweenyEditorStyle::BeginButtonRow();

      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Play, size, false, "Play"))
      {
        tween.Play();
        acted = true;
      }

      TweenyEditorStyle::JoinNext();
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Pause, size, held, held ? "Resume" : "Pause"))
      {
        tween.TogglePause();
        acted = true;
      }

      TweenyEditorStyle::JoinNext();
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Stop, size, false, "Stop and rewind"))
      {
        tween.Rewind(true);
        acted = true;
      }

      TweenyEditorStyle::JoinNext();
      if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Trash, size, false, "Kill"))
      {
        tween.Kill(false);
        acted = true;
      }

      TweenyEditorStyle::EndButtonRow();

      if (acted)
      {
        CometEditor::EditorApplication::RequestSceneRedraw();
      }
    }

    private string NameOf(int index, ITween@ tween)
    {
      if (!tween.GetStringId().isEmpty())
      {
        return tween.GetStringId();
      }
      if (tween.GetIntId() != -999)
      {
        return "id " + tween.GetIntId();
      }
      return "#" + index;
    }

    /// <summary>
    /// The settings behind the selected row, laid out the way the inspector lays out a component.
    ///
    /// The table can only carry what fits in a column. Everything that decides how a tween behaves -- its
    /// delay, its easing, which update phase drives it -- lives here, and it is what you actually need when
    /// a tween is not doing what you expected.
    /// </summary>
    /// <param name="tween">The selected tween.</param>
    private void DrawDetails(ITween@ tween)
    {
      if (tween is null)
      {
        return;
      }

      GUI::SeparatorText("Selected");

      Row("Id", tween.GetStringId().isEmpty()
      ?(tween.GetIntId() == -999 ? "none" : "" + tween.GetIntId())
      : tween.GetStringId());
      Row("Duration", formatFloat(tween.GetDuration(), "", 0, 2) + "s"
      + (tween.GetLoops() == -1 ? ", looping forever"
      : ", " + formatFloat(tween.GetFullDuration(true), "", 0, 2) + "s in total"));
      Row("Position", formatFloat(tween.GetPosition(), "", 0, 2) + "s into the current loop");
      Row("Delay", tween.GetDelay() <= 0.0f
      ? "none"
      :(formatFloat(tween.GetElapsedDelay(), "", 0, 2) + "s of "
      + formatFloat(tween.GetDelay(), "", 0, 2) + "s"));
      Row("Update", UpdateTypeName(tween.GetUpdateType())
      + (tween.IsIndependentUpdate() ? ", ignores time scale" : ""));
      Row("Sequenced", tween.IsSequenced() ? "yes, driven by a sequence" : "no");
    }

    /// <summary>Draws one read-only property row in the editor's standard layout.</summary>
    /// <param name="name">The field name.</param>
    /// <param name="value">The value to show.</param>
    private void Row(const string&in name, const string&in value)
    {
      GUI::StandardFieldName(name);
      GUI::SetCursorAtStandardPropertyWidgetPosition();
      GUI::Text(value);
    }

    private string UpdateTypeName(UpdateType kind)
    {
      switch (kind)
      {
        case UpdateType::Normal: return "Normal";
        case UpdateType::Late: return "Late";
        case UpdateType::Fixed: return "Fixed";
        case UpdateType::Manual: return "Manual";
      }
      return "Normal";
    }

    void OnDestroy()
    {
      Tweeny::PreviewSession().StopOwned(false);
    }
  }
}
