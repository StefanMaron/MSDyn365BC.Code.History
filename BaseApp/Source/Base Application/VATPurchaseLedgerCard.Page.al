page 12442 "VAT Purchase Ledger Card"
{
    Caption = 'VAT Purchase Ledger Card';
    PageType = Document;
    SourceTable = "VAT Ledger";
    SourceTableView = WHERE(Type = CONST(Purchase));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT ledger code.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this VAT ledger.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("From No."; "From No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the first entry number in the VAT ledger.';
                }
                field("To No."; "To No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the end number associated with this VAT ledger.';
                }
                field("Accounting Period"; "Accounting Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the accounting period associated with this VAT ledger.';
                }
                field("Start Page No."; "Start Page No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting page number associated with this VAT ledger.';
                }
            }
            part(PurchSubform; "VAT Purchase Ledger Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = FIELD(Type),
                              Code = FIELD(Code);
            }
            group(Options)
            {
                Caption = 'Options';
                field("C/V Filter"; "C/V Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer filter or vendor filter associated with this VAT ledger.';
                }
                field("VAT Product Group Filter"; "VAT Product Group Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product group filter associated with this VAT ledger.';
                }
                field("VAT Business Group Filter"; "VAT Business Group Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business group filter associated with this VAT ledger.';
                }
                field("Purchase Sorting"; "Purchase Sorting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase sorts that are associated with this VAT ledger.';
                }
                field("Use External Doc. No."; "Use External Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the external document number associated with this VAT ledger will be used.';
                }
                field("Clear Lines"; "Clear Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the lines that are associated with this VAT ledger are cleared.';
                }
                field("Start Numbering"; "Start Numbering")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start number associated with this VAT ledger.';
                }
                field("Other Rates"; "Other Rates")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the other rates that are associated with this VAT ledger.';
                }
                field("Show Realized VAT"; "Show Realized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the realized VAT associated with this VAT ledger is displayed.';
                }
                field("Show Unrealized VAT"; "Show Unrealized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the unrealized VAT associated with this VAT ledger is displayed.';
                }
                field("Show Amount Differences"; "Show Amount Differences")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount differences associated with this VAT ledger are displayed.';
                }
                field("Show Customer Prepayments"; "Show Customer Prepayments")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the customer prepayments associated with this VAT ledger are displayed.';
                }
            }
            group(AddSheetSubForm)
            {
                Caption = 'Additional Sheet';
                field("Total VAT Amt VAT Purch Ledger"; "Total VAT Amt VAT Purch Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total VAT Amount from VAT Purchase Ledger';
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
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("&Create Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Ledger';
                    Image = CreateForm;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create an additional VAT ledger sheet. ';

                    trigger OnAction()
                    begin
                        CreateVATLedger;
                    end;
                }
                action("Create Additional Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Additional Sheet';
                    Image = CreateDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        CreateAddSheet;
                    end;
                }
            }
            group(Print)
            {
                Caption = 'Print';
                Image = Print;
                action("Export Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Ledger';
                    Image = ExportToExcel;
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;
                    ToolTip = 'Export the data in the VAT ledger to Excel.';

                    trigger OnAction()
                    var
                        VATLedgerExport: Report "VAT Ledger Export";
                    begin
                        VATLedgerExport.InitializeReport(Type, Code, false);
                        VATLedgerExport.RunModal;
                    end;
                }
                action("Export Add. Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Add. Sheet';
                    Image = ExportToExcel;
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;
                    ToolTip = 'Export the data in the additional VAT ledger sheet to Excel.';

                    trigger OnAction()
                    var
                        VATLedgerExport: Report "VAT Ledger Export";
                    begin
                        VATLedgerExport.InitializeReport(Type, Code, true);
                        VATLedgerExport.RunModal;
                    end;
                }
                action("Export Ledger XML Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Ledger XML Format';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;
                    ToolTip = 'Export the data in the VAT ledger to an XML file.';

                    trigger OnAction()
                    var
                        VATLedgerExportXML: Report "VAT Ledger Export XML";
                    begin
                        VATLedgerExportXML.InitializeReport(Type, Code, false);
                        VATLedgerExportXML.RunModal;
                    end;
                }
                action("Export Add. Sheet XML Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Add. Sheet XML Format';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = "Report";
                    PromotedIsBig = true;
                    ToolTip = 'Export the data in the additional VAT ledger sheet to an XML file.';

                    trigger OnAction()
                    var
                        VATLedgerExportXML: Report "VAT Ledger Export XML";
                    begin
                        VATLedgerExportXML.InitializeReport(Type, Code, true);
                        VATLedgerExportXML.RunModal;
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CurrPage.PurchSubform.PAGE.NavigateDocument;
                end;
            }
        }
        area(reporting)
        {
        }
    }
}

