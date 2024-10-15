page 35629 "VAT Sales Ledgers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Sales Ledgers';
    CardPageID = "VAT Sales Ledger Card";
    PageType = List;
    SourceTable = "VAT Ledger";
    SourceTableView = WHERE(Type = CONST(Sales));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT ledger code.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this VAT ledger.';
                }
                field("Accounting Period"; "Accounting Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the accounting period associated with this VAT ledger.';
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
                    DrillDown = false;
                    ToolTip = 'Specifies the first entry number in the VAT ledger.';
                    Visible = false;
                }
                field("To No."; "To No.")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the end number associated with this VAT ledger.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1210004; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1210002; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Ledger")
            {
                Caption = '&Ledger';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = VATLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Sales Ledger Card";
                    RunPageLink = Type = FIELD(Type),
                                  Code = FIELD(Code);
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
                }
            }
        }
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
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;

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
        }
    }
}

