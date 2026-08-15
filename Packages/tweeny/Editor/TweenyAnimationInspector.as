using namespace CometEngine;
using namespace CometEditor;

namespace Tweeny
{
	/// <summary>
	/// Puts transport controls at the top of a TweenyAnimation component, so an animation can be tried out
	/// from the inspector without pressing Play and without opening another window.
	///
	/// The buttons come first and the component's own fields follow, drawn by the editor exactly as it would
	/// have drawn them. Previewing here runs the very tween the component would build at play start, and it goes
	/// through the shared preview session, so the Tweeny window shows the same state and its buttons agree with
	/// these ones.
	///
	/// Moving the selection elsewhere stops the preview and puts the targets back, because an animation left
	/// halfway through looks exactly like the object's real position and would be saved into the scene as one.
	/// </summary>
	[CustomInspector("Tweeny::TweenyAnimation")]
	class TweenyAnimationInspector : EditorBehaviour
	{
		void OnCustomInspector(Tweeny::TweenyAnimation@ target)
		{
			DrawTransport(target);
			GUI::SetCursorPosY(GUI::GetCursorPosY() - 7.0F);
			GUI::ShowAllProperties();
		}

		/// <summary>
		/// Drives the preview and ends it when the user looks away.
		///
		/// This runs every editor tick rather than only while the inspector is on screen, which is what makes
		/// both halves work: the animation keeps moving, and deselecting the entity puts it back.
		/// </summary>
		void Update()
		{
			TweenyPreviewSession@ session = Tweeny::PreviewSession();
			session.SetPlayMode(CometEditor::EditorApplication::IsPlaying());
			DropDeselected(session);

			if (session.Advance())
			{
				CometEditor::EditorApplication::RequestSceneRedraw();
			}
		}

		/// <summary>
		/// Ends the previews started here for entities that are no longer selected.
		///
		/// A preview left running once its inspector is off screen is how a scene quietly ends up saved with an
		/// object halfway through an animation. Previews started from the Tweeny window are left alone, because
		/// the window is still there showing them.
		/// </summary>
		/// <param name="session">The shared session.</param>
		private void DropDeselected(TweenyPreviewSession@ session)
		{
			array<TweenyAnimation@>@ mine = session.GetSources(true);
			for (uint i = 0; i < mine.length(); i++)
			{
				TweenyAnimation@ animation = mine[i];
				Entity@ owner = animation.entity;
				if (owner is null || !Object::IsValid(owner) || !CometEditor::Selection::Contains(owner))
				{
					session.StopFor(animation);
					CometEditor::EditorApplication::RequestSceneRedraw();
				}
			}
		}

		/// <summary>
		/// The three transport buttons, centred and joined into one control.
		///
		/// They are drawn as a single block rather than as a property row because they act on the component as a
		/// whole rather than on any one of its fields, and the fields underneath are what the editor's standard
		/// layout is for.
		/// </summary>
		/// <param name="target">The component being inspected.</param>
		private void DrawTransport(TweenyAnimation@ target)
		{
			TweenyPreviewSession@ session = Tweeny::PreviewSession();
			bool running = session.IsPreviewing(target);
			bool paused = running && session.IsPaused();
			float size = TweenyEditorStyle::BUTTON_SIZE;
			bool acted = false;

			GUI::Spacing();
			TweenyEditorStyle::CenterButtonRow(3, size);
			TweenyEditorStyle::BeginButtonRow();

			if (TweenyEditorStyle::RowButton(
			running ? CometEditor::RawIcon::Redo : CometEditor::RawIcon::Play, size, false,
			running ? "Play this animation again from the start"
			: "Preview this animation in the editor"))
			{
				session.Play(target, true);
				acted = true;
			}

			TweenyEditorStyle::JoinNext();
			GUI::BeginDisabled(!running);

			if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Pause, size, paused,
			paused ? "Resume" : "Pause"))
			{
				session.TogglePause();
				acted = true;
			}

			TweenyEditorStyle::JoinNext();
			if (TweenyEditorStyle::RowButton(CometEditor::RawIcon::Stop, size, false,
			"Stop and put everything back"))
			{
				session.StopFor(target);
				acted = true;
			}

			GUI::EndDisabled();
			TweenyEditorStyle::EndButtonRow();

			if (acted)
			{
				CometEditor::EditorApplication::RequestSceneRedraw();
			}
		}

		void OnDestroy()
		{
			Tweeny::PreviewSession().StopOwned(true);
		}
	}
}
