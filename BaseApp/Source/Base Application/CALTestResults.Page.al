page 130405 "CAL Test Results"
{
    Caption = 'CAL Test Results';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Call Stack';
    SourceTable = "CAL Test Result";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Repeater';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field("Test Run No."; "Test Run No.")
                {
                    ApplicationArea = All;
                }
                field("Codeunit ID"; "Codeunit ID")
                {
                    ApplicationArea = All;
                }
                field("Codeunit Name"; "Codeunit Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Function Name"; "Function Name")
                {
                    ApplicationArea = All;
                }
                field(Platform; Platform)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Result; Result)
                {
                    ApplicationArea = All;
                    StyleExpr = Style;
                }
                field(Restore; Restore)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Start Time"; "Start Time")
                {
                    ApplicationArea = All;
                }
                field("Execution Time"; "Execution Time")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                    StyleExpr = TRUE;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(File; File)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("Call Stack")
            {
                ApplicationArea = All;
                Caption = 'Call Stack';
                Image = DesignCodeBehind;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    InStr: InStream;
                    CallStack: Text;
                begin
                    if "Call Stack".HasValue then begin
                        CalcFields("Call Stack");
                        "Call Stack".CreateInStream(InStr);
                        InStr.ReadText(CallStack);
                        Message(CallStack)
                    end;
                end;
            }
            action(Export)
            {
                ApplicationArea = All;
                Caption = 'E&xport';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    CALExportTestResult: XMLport "CAL Export Test Result";
                begin
                    CALExportTestResult.SetTableView(Rec);
                    CALExportTestResult.Run;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Style := GetStyle;
    end;

    var
        Style: Text;

    local procedure GetStyle(): Text
    begin
        case Result of
            Result::Passed:
                exit('Favorable');
            Result::Failed:
                exit('Unfavorable');
            Result::Inconclusive:
                exit('Ambiguous');
            else
                exit('Standard');
        end;
    end;
}

