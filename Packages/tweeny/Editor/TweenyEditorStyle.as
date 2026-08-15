using namespace CometEngine;
using namespace CometEditor;

/// <summary>
/// The look of Tweeny's transport controls, kept in one place so every panel draws them the same.
///
/// It is the editor's own toolbar style, the one the Bezier curve gizmo uses: square buttons with a hairline
/// border in the separator colour, no rounding, and each one pulled back by the item spacing so neighbours
/// share an edge and the row reads as a single control rather than as loose buttons.
/// </summary>
namespace TweenyEditorStyle
{
  /// <summary>Side of a toolbar button, in the unscaled units the editor's GUI works in.</summary>
  const float BUTTON_SIZE = 25.0f;

  /// <summary>
  /// Starts a joined row of toolbar buttons. Every row has to be closed with EndButtonRow.
  /// </summary>
  void BeginButtonRow()
  {
    GUI::PushStyleVarNum(int(GUI::StyleVar::FrameBorderSize), 1.0f);
    GUI::PushStyleVarNum(int(GUI::StyleVar::FrameRounding), 0.0f);
    GUI::PushStyleColor(int(GUI::Col::Border), GUI::GetStyleColor(GUI::Col::Separator));
    GUI::PushStyleColor(int(GUI::Col::BorderShadow), Color(0.0f, 0.0f, 0.0f, 0.0f));
  }

  /// <summary>Closes a row opened with BeginButtonRow.</summary>
  void EndButtonRow()
  {
    GUI::PopStyleColor(2);
    GUI::PopStyleVar(2);
  }

  /// <summary>
  /// Draws one button of a joined row.
  /// </summary>
  /// <param name="icon">The icon to show.</param>
  /// <param name="size">Side of the square button.</param>
  /// <param name="active">Whether it is held down, drawn in the pressed colour.</param>
  /// <param name="tooltip">Text to show on hover.</param>
  /// <returns>Returns true on the frame it is clicked.</returns>
  bool RowButton(const string&in icon, float size, bool active, const string&in tooltip)
  {
    if (active)
    {
      GUI::PushStyleColor(int(GUI::Col::Button), GUI::GetStyleColor(GUI::Col::ButtonActive));
    }
    bool clicked = GUI::Button(icon, Vector2(size, size));
    if (active)
    {
      GUI::PopStyleColor();
    }
    GUI::Tooltip(tooltip);
    return clicked;
  }

  /// <summary>
  /// Places the next button hard against the one just drawn, so the two share a border rather than
  /// showing two of them with a gap between.
  /// </summary>
  void JoinNext()
  {
    GUI::SameLine();
    GUI::SetCursorPosX(GUI::GetCursorPosX() - GUI::GetStyleVarVector(GUI::StyleVar::ItemSpacing).x);
  }

  /// <summary>
  /// Total width a joined row of square buttons takes, which is what centring or right-aligning it needs.
  /// </summary>
  /// <param name="count">How many buttons the row has.</param>
  /// <param name="size">Side of each button.</param>
  /// <returns>Returns the width in unscaled units.</returns>
  float RowWidth(int count, float size)
  {
    if (count <= 0)
    {
      return 0.0f;
    }
    return size * float(count);
  }

  /// <summary>
  /// Moves the cursor so a joined row of buttons sits in the middle of the space left on this line.
  ///
  /// Worth doing even where the space was measured to fit the row exactly: the last column of a table takes
  /// whatever width is left over once the others have been laid out, so the room the buttons get is never
  /// quite the room they asked for.
  /// </summary>
  /// <param name="count">How many buttons the row has.</param>
  /// <param name="size">Side of each button.</param>
  void CenterButtonRow(int count, float size)
  {
    float offset = (GUI::GetContentRegionAvail().x - RowWidth(count, size)) * 0.5f;
    if (offset > 0.0f)
    {
      GUI::SetCursorPosX(GUI::GetCursorPosX() + offset);
    }
  }

  /// <summary>
  /// Width to give a table column that carries nothing but a joined row of buttons.
  ///
  /// It is the row itself plus the padding the table puts on either side of a cell, so the column ends
  /// exactly where the last button does. Anything wider leaves the controls floating in empty space; the
  /// padding cannot be left out, because the table would then clip the last button.
  /// </summary>
  /// <param name="count">How many buttons the row has.</param>
  /// <param name="size">Side of each button.</param>
  /// <returns>Returns the width in unscaled units.</returns>
  float ControlsColumnWidth(int count, float size)
  {
    return RowWidth(count, size) + GUI::GetStyleVarVector(GUI::StyleVar::CellPadding).x * 2.0f;
  }

  /// <summary>
  /// Draws a progress bar filling the width available to it.
  /// </summary>
  /// <param name="fraction">How full it is, from 0 to 1.</param>
  /// <param name="tooltip">Text to show on hover.</param>
  void ProgressBar(float fraction, const string&in tooltip)
  {
    if (fraction < 0.0f)
    {
      fraction = 0.0f;
    }
    if (fraction > 1.0f)
    {
      fraction = 1.0f;
    }

    float width = GUI::GetContentRegionAvail().x;
    float height = GUI::GetFrameHeight() * 0.55f;
    Vector2 origin = GUI::GetCursorScreenPos();
    origin.y += (GUI::GetFrameHeight() - height) * 0.5f;
    Vector2 far = Vector2(origin.x + width, origin.y + height);

    GUI::DrawRectFilled(origin, far, GUI::GetStyleColor(GUI::Col::FrameBg), 2.0f);
    if (fraction > 0.0f)
    {
      GUI::DrawRectFilled(origin, Vector2(origin.x + width * fraction, far.y),
      GUI::GetStyleColor(GUI::Col::PlotHistogram), 2.0f);
    }
    GUI::Dummy(Vector2(width, GUI::GetFrameHeight()));
    GUI::Tooltip(tooltip);
  }
}
