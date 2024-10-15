page 740 "VAT Report"
{
    Caption = 'VAT Report';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,VAT Settlement';
    SourceTable = "VAT Report Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("VAT Report Config. Code"; "VAT Report Config. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the appropriate configuration code.';

                    trigger OnValidate()
                    begin
                        ReportPrintable := not isDatifattura;
                    end;
                }
                field("VAT Report Type"; "VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Original Report No."; "Original Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original VAT report if the VAT Report Type field is set to a value other than Standard.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field("Tax Auth. Receipt No."; "Tax Auth. Receipt No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt number that you received from the tax authorities when you submitted the VAT transactions report.';
                }
#if not CLEAN19                
                field("Tax Auth. Doc. No."; "Tax Auth. Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number that is provided by the tax authority after you submit a VAT data transmission.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Tax Auth. Document No.';
                    ObsoleteTag = '19.0';
                }
#endif                
                field("Tax Auth. Document No."; "Tax Auth. Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number that is provided by the tax authority after you submit a VAT Data transmission.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
                field("Amounts in Add. Rep. Currency"; "Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the amounts are in the additional reporting currency.';
                }
            }
            part(VATReportLines; "VAT Report Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "VAT Report No." = FIELD("No.");
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
                action(SuggestLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Lines';
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Suggest Tax lines.';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
                    end;
                }
                separator(Action23)
                {
                }
                action("&Release")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the Tax report to indicate that it has been printed or exported. The status then changes to Released.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Release(Rec);
                    end;
                }
                action("Mark as Su&bmitted")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark as Su&bmitted';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Mark the lines for submission to the Tax authorities.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Reopen the Tax report to indicate that it must be printed or exported again, for example because it has been corrected.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                    end;
                }
                separator(Action26)
                {
                }
                action("&Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Export the Tax report.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Enabled = ReportPrintable;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReportPrintable := not isDatifattura;
    end;

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        ReportPrintable: Boolean;
}

