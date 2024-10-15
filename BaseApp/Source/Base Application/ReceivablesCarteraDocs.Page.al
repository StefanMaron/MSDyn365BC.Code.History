page 7000001 "Receivables Cartera Docs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Receivables Docs';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "Cartera Doc." = m;
    SaveValues = true;
    SourceTable = "Cartera Doc.";
    SourceTableView = SORTING(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Accepted, "Due Date", Place)
                      WHERE(Type = CONST(Receivable),
                            "Bill Gr./Pmt. Order No." = FILTER(= ''));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CategoryFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document in question.';
                }
                field("Collection Agent"; "Collection Agent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agent in which this document is settled.';
                }
                field(Accepted; Accepted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Acceptance status required for a bill.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the when the creation of this document was posted.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of this document.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment method code defined for the document number.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document used to generate this document.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number associated with a specific bill.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this document.';
                }
                field("Original Amount (LCY)"; "Original Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document, in LCY.';
                    Visible = false;
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document.';
                    Visible = false;
                }
                field("Remaining Amt. (LCY)"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending amount, in order for the document to be settled in full.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending payment amount for the document to be settled in full.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code in which this document was generated.';
                    Visible = false;
                }
                field(Place; Place)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the company bank and customer bank are in the same area.';
                    Visible = false;
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a category code for this document.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number of the customer/vendor associated with this document.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ledger entry number associated with the posting of this document.';
                }
                field("Cust./Vendor Bank Acc. Code"; "Cust./Vendor Bank Acc. Code")
                {
                    ApplicationArea = Basic, Suite;
		            ToolTip = 'Specifies the bank account code of the customer/vendor associated with this document.';
                }
            }
            group(Control49)
            {
                ShowCaption = false;
                field(CurrTotalAmount; CurrTotalAmountLCY)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Total Rmg. Amt. (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the sum of amounts that remain to be paid.';
                    Visible = CurrTotalAmountVisible;
                }
            }
        }
        area(factboxes)
        {
            part(Control1901421107; "Rec. Docs Analysis Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = CONST(Receivable),
                              "Entry No." = FIELD("Entry No.");
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Docs.")
            {
                Caption = '&Docs.';
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';

                    trigger OnAction()
                    begin
                        Doc.Copy(Rec);
                        PAGE.Run(PAGE::"Documents Analysis", Doc);
                    end;
                }
                separator(Action55)
                {
                }
                action("Dime&nsions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dime&nsions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                separator(Action58)
                {
                }
                action(Categorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Categorize';
                    Ellipsis = true;
                    Image = Category;
                    ToolTip = 'Insert categories on one or more Cartera documents to facilitate analysis. For example, to count or add only some documents, to analyze their due dates, to simulate scenarios for creating bill groups, to mark documents with your initials to indicate to other accountants that you are managing them personally.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Doc);
                        CarteraManagement.CategorizeDocs(Doc);
                    end;
                }
                action(Decategorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Decategorize';
                    Image = UndoCategory;
                    ToolTip = 'Remove categories applied to one or more Cartera documents to facilitate analysis.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(Doc);
                        CarteraManagement.DecategorizeDocs(Doc);
                    end;
                }
                separator(Action37)
                {
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Ellipsis = true;
                    Image = Reject;
                    ToolTip = 'Post document rejections.';

                    trigger OnAction()
                    var
                        Cust: Record Customer;
                    begin
                        if Doc.Type = Doc.Type::Receivable then
                            if Cust.Get("Account No.") then
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                        Reject;
                    end;
                }
                separator(Action39)
                {
                }
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Print the document.';

                    trigger OnAction()
                    begin
                        PrintDoc;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CarteraManagement.NavigateDoc(Rec);
                end;
            }
            action("Documents Maturity")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Documents Maturity';
                Image = DocumentsMaturity;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Documents Maturity";
                RunPageLink = Type = FILTER(Receivable),
                              "Bill Gr./Pmt. Order No." = FILTER('');
                ToolTip = 'View the document lines that have matured. Maturity information can be viewed by period start date.';
            }
        }
        area(reporting)
        {
            action("Receivable Bill")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Receivable Bill';
                Image = ReceivableBill;
                Promoted = true;
                PromotedCategory = "Report";
                ToolTip = 'View a report that contains the selected receivable bills.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Doc);
                    if not Doc.Find('-') then
                        exit;

                    if (Doc.Type <> Doc.Type::Receivable) and (Doc."Document Type" = Doc."Document Type"::Bill) then
                        Error(Text1100000);

                    if Doc.Type = Doc.Type::Receivable then begin
                        if Doc."Document Type" = Doc."Document Type"::Bill then begin
                            CustLedgEntry.Reset();
                            repeat
                                CustLedgEntry.Get(Doc."Entry No.");
                                CustLedgEntry.Mark(true);
                            until Doc.Next = 0;

                            CustLedgEntry.MarkedOnly(true);
                            CustLedgEntry.PrintBill(true);
                        end;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnInit()
    begin
        CurrTotalAmountVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Document-Edit", Rec);
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    begin
        CategoryFilter := GetFilter("Category Code");
        UpdateStatistics;
    end;

    var
        Text1100000: Label 'Payable Bills cannot be printed.';
        Text1100001: Label 'Only Receivable Bills can be rejected.';
        Text1100002: Label 'Only  Bills can be rejected.';
        Doc: Record "Cartera Doc.";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CarteraManagement: Codeunit CarteraManagement;
        CategoryFilter: Code[250];
        CurrTotalAmountLCY: Decimal;
        ShowCurrent: Boolean;
        [InDataSet]
        CurrTotalAmountVisible: Boolean;

    procedure UpdateStatistics()
    begin
        Doc.Copy(Rec);
        CarteraManagement.UpdateStatistics(Doc, CurrTotalAmountLCY, ShowCurrent);
        CurrTotalAmountVisible := ShowCurrent;
    end;

    procedure GetSelected(var NewDoc: Record "Cartera Doc.")
    begin
        CurrPage.SetSelectionFilter(NewDoc);
    end;

    procedure PrintDoc()
    begin
        CurrPage.SetSelectionFilter(Doc);
        if not Doc.Find('-') then
            exit;

        if (Doc.Type <> Doc.Type::Receivable) and (Doc."Document Type" = Doc."Document Type"::Bill) then
            Error(Text1100000);

        if Doc.Type = Doc.Type::Receivable then begin
            if Doc."Document Type" = Doc."Document Type"::Bill then begin
                CustLedgEntry.Reset();
                repeat
                    CustLedgEntry.Get(Doc."Entry No.");
                    CustLedgEntry.Mark(true);
                until Doc.Next = 0;

                CustLedgEntry.MarkedOnly(true);
                CustLedgEntry.PrintBill(true);
            end else begin
                SalesInvHeader.Reset();
                repeat
                    SalesInvHeader.Get(Doc."Document No.");
                    SalesInvHeader.Mark(true);
                until Doc.Next = 0;

                SalesInvHeader.MarkedOnly(true);
                SalesInvHeader.PrintRecords(true);
            end;
        end else begin
            PurchInvHeader.Reset();
            repeat
                PurchInvHeader.Get(Doc."Document No.");
                PurchInvHeader.Mark(true);
            until Doc.Next = 0;

            PurchInvHeader.MarkedOnly(true);
            PurchInvHeader.PrintRecords(true);
        end;
    end;

    procedure Reject()
    begin
        if Doc.Type <> Doc.Type::Receivable then
            Error(Text1100001);
        if Doc."Document Type" <> "Document Type"::Bill then
            Error(Text1100002);

        CurrPage.SetSelectionFilter(Doc);
        if not Doc.Find('-') then
            exit;

        CustLedgEntry.Reset();
        repeat
            CustLedgEntry.Get(Doc."Entry No.");
            CustLedgEntry.Mark(true);
        until Doc.Next = 0;

        CustLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Reject Docs.", true, false, CustLedgEntry);
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        SetFilter("Category Code", CategoryFilter);
        CurrPage.Update(false);
        UpdateStatistics;
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        UpdateStatistics;
    end;
}

