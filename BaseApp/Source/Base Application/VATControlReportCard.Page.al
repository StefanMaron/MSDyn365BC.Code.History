page 31101 "VAT Control Report Card"
{
    Caption = 'VAT Control Report Card';
    PageType = Card;
    SourceTable = "VAT Control Report Header";

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of VAT control report.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of VAT control report.';
                }
                field("Report Period"; "Report Period")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the VAT period (month or quarter).';
                }
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT period.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the year of report';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies first date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies end date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("Created Date"; "Created Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies date of creating control report card.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of vat control report';
                }
            }
            part(Control1220028; "VAT Control Report Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Control Report No." = FIELD("No."),
                              "Closed by Document No." = FIELD("Closed by Document No. Filter");
                SubPageView = SORTING("Control Report No.", "Line No.");
            }
            group(Other)
            {
                Caption = 'Other';
                field("Perform. Country/Region Code"; "Perform. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code. It is mandatory field by creating documents with VAT registration number for other countries.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("VAT Statement Template Name"; "VAT Statement Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT statement template name for VAT control report creation.';
                }
                field("VAT Statement Name"; "VAT Statement Name")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the VAT statement name for VAT control report creation.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220016; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220015; Notes)
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
            group("&Report")
            {
                Caption = '&Report';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View the statistics on the selected VAT control report.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"VAT Control Report Statistics", Rec);
                    end;
                }
            }
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release vies declaration';

                    trigger OnAction()
                    begin
                        ReleaseVATControlReport.Run(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Opens VAT Control Report';

                    trigger OnAction()
                    begin
                        ReleaseVATControlReport.Reopen(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("&Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Image = Export;
                    ToolTip = 'This batch job exported control report in XML format.';

                    trigger OnAction()
                    begin
                        Export;
                    end;
                }
                action("C&lose Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lose Lines';
                    Image = Close;
                    ToolTip = 'This batch job closed lines of VAT control report.';

                    trigger OnAction()
                    begin
                        CloseLines;
                    end;
                }
                action("&Check - Internal Doc.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Check - Internal Doc.';
                    Image = Check;
                    ToolTip = 'This batch job opens the report for checking of internal document.';

                    trigger OnAction()
                    var
                        VATControlReportMgt: Codeunit VATControlReportManagement;
                    begin
                        VATControlReportMgt.ExportInternalDocCheckToExcel(Rec, true);
                    end;
                }
                action("&Suggest Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'This batch job suggests lines in VAT control report.';

                    trigger OnAction()
                    begin
                        SuggestLines;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'Specifies test report';

                    trigger OnAction()
                    begin
                        PrintTestReport;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDocNoVisible();
    end;

    var
        ReleaseVATControlReport: Codeunit "Release VAT Control Report";
        DocNoVisible: Boolean;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option "VIES Declaration","Reverse Charge","VAT Control Report";
    begin
        DocNoVisible := DocumentNoVisibility.StatReportingDocumentNoIsVisible(DocType::"VAT Control Report", "No.");
    end;
}

