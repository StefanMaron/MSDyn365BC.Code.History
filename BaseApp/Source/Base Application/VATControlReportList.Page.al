page 31100 "VAT Control Report List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Control Reports';
    CardPageID = "VAT Control Report Card";
    Editable = false;
    PageType = List;
    SourceTable = "VAT Control Report Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of VAT control report.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of VAT control report.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies first date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies last date for the declaration, which is calculated based of the values of the Period No. a Year fields.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of vat control report list';
                }
                field("VAT Statement Template Name"; "VAT Statement Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT statement template name for VAT control report creation.';
                }
                field("VAT Statement Name"; "VAT Statement Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT statement name for VAT control report creation.';
                }
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
                    ToolTip = 'Release vat control report';

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

    var
        ReleaseVATControlReport: Codeunit "Release VAT Control Report";
}

