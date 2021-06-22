page 601 "IC Dimension Values"
{
    Caption = 'Intercompany Dimension Values';
    DataCaptionFields = "Dimension Code";
    PageType = List;
    SourceTable = "IC Dimension Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the dimension code.';
                }
                field("Dimension Value Type"; "Dimension Value Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to Dimension Value Code"; "Map-to Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which intercompany dimension value corresponds to the dimension value on the line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Indent IC Dimension Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Indent IC Dimension Values';
                    Image = Indent;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    RunObject = Codeunit "IC Dimension Value-Indent";
                    ToolTip = 'Indent the names of all dimension values between each set of Begin-Total and End-Total dimension values. It will also enter a totaling interval for each End-Total dimension value.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine;
    end;

    var
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure FormatLine()
    begin
        Emphasize := "Dimension Value Type" <> "Dimension Value Type"::Standard;
        NameIndent := Indentation;
    end;
}

