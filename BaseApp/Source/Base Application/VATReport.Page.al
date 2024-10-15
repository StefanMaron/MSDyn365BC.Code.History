page 740 "VAT Report"
{
    Caption = 'VAT Report';
    PageType = Document;
    SourceTable = "VAT Report Header";
    SourceTableView = WHERE("VAT Report Config. Code" = CONST(VIES));

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
                field("VAT Report Type"; "VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Trade Type"; "Trade Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the trade, such as sales.';
                }
                field("EU Goods/Services"; "EU Goods/Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what types of transactions the report covers, such as goods or services.';
                }
                field("Report Period Type"; "Report Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reporting period for the VAT report.';
                }
                field("Report Period No."; "Report Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Indicates the VAT period.';
                }
                field("Report Year"; "Report Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year that the VAT report covers.';
                }
                field("Processing Date"; "Processing Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT report was created.';
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
                field("Original Report No."; "Original Report No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Test Export"; "Test Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to test the export file first. The report must have the Status Open in order to select the Test Export check box.';
                }
                field(Notice; Notice)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to include notice in the VAT report.';
                }
                field(Revocation; Revocation)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Indicates whether the report has been revoked .';
                }
                field("Total Base"; "Total Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated sum of the base amount of the exported lines.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated total amount of VAT, in euros.';
                }
                field("Total Number of Supplies"; "Total Number of Supplies")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of G/L transactions that make up the Total Amount.';
                }
            }
            group(Company)
            {
                Caption = 'Company';
                Visible = false;
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company name that is associated with the VAT report.';
                }
                field("Company Address"; "Company Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company associated with the VAT report.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the company submitting the VAT report.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the company submitting the VAT report.';
                }
                field("Tax Office ID"; "Tax Office ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Tax Office ID of the company submitting the VAT report.';
                }
            }
            group("Sign-off")
            {
                Caption = 'Sign-off';
                field("Sign-off Place"; "Sign-off Place")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the location where the VAT report has been signed off.';
                }
                field("Sign-off Date"; "Sign-off Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT report has been signed off.';
                }
                field("Signed by Employee No."; "Signed by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the employee who signed the VAT report.';
                }
                field("Created by Employee No."; "Created by Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the employee who created the VAT report.';
                }
            }
            part(VATReportLines; "VAT Report Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "VAT Report No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(740),
                              "No." = FIELD("No."),
                              "VAT Report Config. Code" = FIELD("VAT Report Config. Code");
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
                    Image = SuggestGrid;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Suggest Tax lines.';

                    trigger OnAction()
                    begin
                        VATReportMediator.GetLines(Rec);
                    end;
                }
                action("Co&rrect Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&rrect Lines';
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        VATReportMediator.CorrectLines(Rec);
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
        }
    }

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
}

