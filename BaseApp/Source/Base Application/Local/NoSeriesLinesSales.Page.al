page 12145 "No. Series Lines Sales"
{
    AutoSplitKey = true;
    Caption = 'No. Series Lines Sales';
    DataCaptionFields = "Series Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "No. Series Line Sales";
    SourceTableView = SORTING("Series Code", "Starting Date", "Starting No.");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code for the line.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which you would like this line to apply.';
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first number in the series.';
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number in the series.';
                }
                field("Last Date Used"; Rec."Last Date Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when a number was most recently assigned from the number series.';
                }
                field("Last No. Used"; Rec."Last No. Used")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last number that was used from the number series.';
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to receive a warning that the number series is running out.';
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval by which you would like to space the numbers in the number series.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not the number series line is open.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if NoSeriesLine.Get("Series Code", "Line No.") then begin
            NoSeriesLine.SetRange("Series Code", "Series Code");
            if NoSeriesLine.FindLast() then;
            "Line No." := NoSeriesLine."Line No." + 10000;
        end;
        exit(true);
    end;

    var
        NoSeriesLine: Record "No. Series Line Sales";
}

