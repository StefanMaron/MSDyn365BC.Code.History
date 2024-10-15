page 11000014 "CBG Statement Line Add. Info."
{
    AutoSplitKey = true;
    Caption = 'CBG Statement Line Add. Info.';
    PageType = List;
    SourceTable = "CBG Statement Line Add. Info.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the journal template the additional information belongs to.';
                    Visible = "Journal Template NameVisible";
                }
                field("CBG Statement No."; Rec."CBG Statement No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the CBG statement number.';
                    Visible = "CBG Statement No.Visible";
                }
                field("CBG Statement Line No."; Rec."CBG Statement Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number of the CBG statement line.';
                    Visible = "CBG Statement Line No.Visible";
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line''s number.';
                    Visible = false;
                }
                field("Information Type"; Rec."Information Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of information that will be stored in the Text field.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the various types of information stored in this field during the import of an electronic bank statement.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        "CBG Statement Line No.Visible" := true;
        "CBG Statement No.Visible" := true;
        "Journal Template NameVisible" := true;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(10);
        "Journal Template NameVisible" := GetFilter("Journal Template Name") = '';
        "CBG Statement No.Visible" := GetFilter("CBG Statement No.") = '';
        "CBG Statement Line No.Visible" := GetFilter("CBG Statement Line No.") = '';
        FilterGroup(0);
    end;

    var
        [InDataSet]
        "Journal Template NameVisible": Boolean;
        [InDataSet]
        "CBG Statement No.Visible": Boolean;
        [InDataSet]
        "CBG Statement Line No.Visible": Boolean;
}

