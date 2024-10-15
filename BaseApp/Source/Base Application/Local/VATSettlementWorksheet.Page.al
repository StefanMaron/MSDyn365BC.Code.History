page 14925 "VAT Settlement Worksheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Settlement Worksheet';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "VAT Document Entry Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    OptionCaption = ',Purchase,Sale,Fixed Asset,Future Expense';

                    trigger OnValidate()
                    begin
                        TypeValidation;
                        TypeOnAfterValidate();
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
            }
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Allocated VAT Amount"; Rec."Allocated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the allocated VAT amount associated with the worksheet line.';

                    trigger OnDrillDown()
                    begin
                        DrillDownVATAllocation;
                        CalcFields("VAT Amount To Allocate");
                        "Allocated VAT Amount" := "VAT Amount To Allocate";
                        CurrPage.Update(true);
                    end;
                }
                field("""Unrealized VAT Amount"" - ""Realized VAT Amount"""; Rec."Unrealized VAT Amount" - "Realized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining VAT Amount';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the VAT amount that remains to be processed.';

                    trigger OnDrillDown()
                    begin
                        RemVATDrillDown("Entry No.");
                    end;
                }
                field("Realized VAT Amount"; Rec."Realized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Realized VAT Base"; Rec."Realized VAT Base")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Unrealized VAT Amount"; Rec."Unrealized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
                }
                field("Unrealized VAT Base"; Rec."Unrealized VAT Base")
                {
                    Editable = false;
                    ToolTip = 'Specifies the unrealized base amount if you use unrealized VAT.';
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("CV No."; Rec."CV No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the creditor or debitor.';
                }
                field("CV Name"; Rec."CV Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the creditor or debitor.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Changed Vendor VAT Invoice"; Rec."Changed Vendor VAT Invoice")
                {
                    ApplicationArea = All;
                    Visible = ChangedVendorVATInvoiceVisible;
                }
                field("Vendor VAT Invoice No."; Rec."Vendor VAT Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related vendor VAT invoice number.';
                    Visible = VendorVATInvoiceNoVisible;
                }
                field("Vendor VAT Invoice Date"; Rec."Vendor VAT Invoice Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related vendor VAT invoice number.';
                    Visible = VendorVATInvoiceDateVisible;
                }
                field("Vendor VAT Invoice Rcvd Date"; Rec."Vendor VAT Invoice Rcvd Date")
                {
                    ApplicationArea = All;
                    Visible = VendorVATInvoiceRcvdDateVisibl;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Incl. VAT';
                    Editable = false;
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be paid, expressed in LCY.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ToolTip = 'Specifies the transaction''s entry number.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger Entry';
                    Image = VendorLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'View the related transaction.';

                    trigger OnAction()
                    begin
                        ShowCVEntry;
                    end;
                }
                action("&VAT Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&VAT Entries';
                    Image = VATLedger;
                    RunObject = Page "VAT Entries";
                    RunPageLink = "CV Ledg. Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Transaction No.", "CV Ledg. Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Suggest &Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest &Documents';
                    Image = MakeOrder;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Use a function to insert document lines for VAT settlement. ';

                    trigger OnAction()
                    begin
                        VATSettlementMgt.Generate(Rec, Type);
                        UpdateForm;
                    end;
                }
                separator(Action1210002)
                {
                }
                action("Set &Group VAT Allocation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set &Group VAT Allocation';
                    Image = Track;
                    ToolTip = 'Allocate VAT according to the specified groups.';

                    trigger OnAction()
                    begin
                        SetGroupVATAlloc;
                    end;
                }
                action("Change Vendor VAT &Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Vendor VAT &Invoices';
                    Image = DocumentEdit;

                    trigger OnAction()
                    begin
                        ChangeVendVATInvoices(false);
                    end;
                }
                separator(Action1210010)
                {
                }
                action("&Copy Lines to Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Copy Lines to Journal';
                    Image = SelectLineToApply;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    var
                        VATSettlementJnl: Page "VAT Settlement Journal";
                    begin
                        Clear(VATSettlementJnl);
                        CopySelectionToJnl;
                        VATSettlementJnl.Run();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Document Date", "Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Suggest &Documents_Promoted"; "Suggest &Documents")
                {
                }
                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("Change Vendor VAT &Invoices_Promoted"; "Change Vendor VAT &Invoices")
                {
                }
                actionref("&Copy Lines to Journal_Promoted"; "&Copy Lines to Journal")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcVATAmount;
    end;

    trigger OnInit()
    begin
        VendorVATInvoiceRcvdDateVisibl := true;
        VendorVATInvoiceDateVisible := true;
        VendorVATInvoiceNoVisible := true;
        ChangedVendorVATInvoiceVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Type := Type::Purchase;
        PeriodType := PeriodType::Month;
        AmountType := AmountType::"Balance at Date";
        TypeValidation;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ChangeVendVATInvoices(true);
    end;

    var
        UserSetup: Record "User Setup";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Type: Option ,Purchase,Sale,"Fixed Asset","Future Expense";
        xType: Option ,Purchase,Sale,"Fixed Asset","Future Expense";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        Text002: Label 'There is nothing to allocate.';
        Text003: Label 'There are lines in which %1 is Yes. Do you want to apply these changes? ';
        [InDataSet]
        ChangedVendorVATInvoiceVisible: Boolean;
        [InDataSet]
        VendorVATInvoiceNoVisible: Boolean;
        [InDataSet]
        VendorVATInvoiceDateVisible: Boolean;
        [InDataSet]
        VendorVATInvoiceRcvdDateVisibl: Boolean;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        if Calendar."Period Start" = Calendar."Period End" then begin
            if AmountType = AmountType::"Net Change" then
                SetRange("Date Filter", Calendar."Period Start")
            else
                SetRange("Date Filter", 0D, Calendar."Period Start");
        end else
            if AmountType = AmountType::"Net Change" then
                SetRange("Date Filter", Calendar."Period Start", Calendar."Period End")
            else
                SetRange("Date Filter", 0D, Calendar."Period End");
    end;

    local procedure FindUserPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if UserSetup.Get(UserId) then begin
            SetRange("Date Filter", UserSetup."Allow Posting From", UserSetup."Allow Posting To");
            if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                SetRange("Date Filter", GetRangeMin("Date Filter"));
        end else begin
            if GetFilter("Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
                if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                    PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
            SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                SetRange("Date Filter", GetRangeMin("Date Filter"));
        end;
    end;

    [Scope('OnPrem')]
    procedure RemVATDrillDown(CVEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        VATEntries: Page "VAT Entries";
    begin
        VATEntry.SetRange("CV Ledg. Entry No.", CVEntryNo);
        VATEntry.SetRange("Unrealized VAT Entry No.", 0);
        VATEntry.SetFilter("Remaining Unrealized Amount", '<>%1', 0);
        VATEntry.SetFilter("VAT Settlement Type", GetFilter("Type Filter"));
        VATEntry.SetRange("Manual VAT Settlement", true);
        VATEntry.SetFilter("VAT Bus. Posting Group", GetFilter("VAT Bus. Posting Group Filter"));
        VATEntry.SetFilter("VAT Prod. Posting Group", GetFilter("VAT Prod. Posting Group Filter"));
        VATEntries.SetTableView(VATEntry);
        VATEntries.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CopySelectionToJnl()
    var
        EntryToPost: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        Filters: Record "VAT Document Entry Buffer";
        CurrRec: Record "VAT Document Entry Buffer";
    begin
        CurrRec := Rec;
        Filters.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if FindSet() then
            repeat
                CalcVATAmount;
                if "Allocated VAT Amount" <> 0 then begin
                    EntryToPost := Rec;
                    EntryToPost.Insert();
                end;
            until Next() = 0;
        Rec := CurrRec;
        Reset();
        CopyFilters(Filters);

        EntryToPost.Reset();
        EntryToPost.SetFilter("Type Filter", GetFilter("Type Filter"));
        EntryToPost.SetFilter("Date Filter", GetFilter("Date Filter"));
        VATEntry.SetFilter("VAT Bus. Posting Group", GetFilter("VAT Bus. Posting Group Filter"));
        VATEntry.SetFilter("VAT Prod. Posting Group", GetFilter("VAT Prod. Posting Group Filter"));
        if EntryToPost.IsEmpty() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        VATSettlementMgt.CopyToJnl(EntryToPost, VATEntry);
        EntryToPost.Reset();
        EntryToPost.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DrillDownVATAllocation()
    var
        VATAllocationLine: Record "VAT Allocation Line";
        VATAllocation: Page "VAT Allocation";
    begin
        Clear(VATAllocation);
        VATAllocationLine.Reset();
        VATAllocationLine.SetCurrentKey("CV Ledger Entry No.");
        VATAllocationLine.SetRange("CV Ledger Entry No.", "Entry No.");
        VATAllocationLine.SetFilter("VAT Settlement Type", GetFilter("Type Filter"));
        VATAllocationLine.SetFilter("VAT Bus. Posting Group", GetFilter("VAT Bus. Posting Group Filter"));
        VATAllocationLine.SetFilter("VAT Prod. Posting Group", GetFilter("VAT Prod. Posting Group Filter"));
        VATAllocationLine.SetFilter("Posting Date Filter", GetFilter("Date Filter"));
        VATAllocation.SetTableView(VATAllocationLine);
        VATAllocation.RunModal();
    end;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        ChangedVendorVATInvoiceVisible := "Entry Type" = "Entry Type"::Purchase;
        VendorVATInvoiceNoVisible := "Entry Type" = "Entry Type"::Purchase;
        VendorVATInvoiceDateVisible := "Entry Type" = "Entry Type"::Purchase;
        VendorVATInvoiceRcvdDateVisibl := "Entry Type" = "Entry Type"::Purchase;
    end;

    [Scope('OnPrem')]
    procedure SetGroupVATAlloc()
    var
        VATEntry: Record "VAT Entry";
        Filters: Record "VAT Document Entry Buffer";
        EntryNo: Record "Integer" temporary;
        CurrRec: Record "VAT Document Entry Buffer";
    begin
        CurrRec := Rec;
        Filters.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if FindFirst() then
            repeat
                EntryNo.Number := "Entry No.";
                EntryNo.Insert();
            until Next() = 0;
        if EntryNo.IsEmpty() then
            Error(Text002);

        VATEntry.SetFilter(Type, GetFilter("Entry Type"));
        VATEntry.SetFilter("Posting Date", GetFilter("Date Filter"));
        VATEntry.SetFilter("VAT Settlement Type", GetFilter("Type Filter"));
        VATEntry.SetRange("Unrealized VAT Entry No.", 0);
        VATEntry.SetFilter("VAT Bus. Posting Group", GetFilter("VAT Bus. Posting Group Filter"));
        VATEntry.SetFilter("VAT Prod. Posting Group", GetFilter("VAT Prod. Posting Group Filter"));
        VATEntry.SetRange("Manual VAT Settlement", true);
        if VATSettlementMgt.SetGroupVATAlloc(VATEntry, EntryNo) then begin
            FindSet();
            repeat
                CalcFields("VAT Amount To Allocate");
                "Allocated VAT Amount" := "VAT Amount To Allocate";
            until Next() = 0;
        end;
        EntryNo.DeleteAll();

        Rec := CurrRec;
        Reset();
        CopyFilters(Filters);
        CurrPage.Update(true);
    end;

    [Scope('OnPrem')]
    procedure TypeValidation()
    begin
        if Type <> xType then begin
            xType := Type;
            Reset();
            DeleteAll();
            case Type of
                Type::Purchase, Type::Sale:
                    SetRange("Type Filter", "Type Filter"::" ");
                Type::"Fixed Asset":
                    SetRange("Type Filter", "Type Filter"::"by Act");
                Type::"Future Expense":
                    SetRange("Type Filter", "Type Filter"::"Future Expenses");
            end;
            if PeriodType = PeriodType::"Accounting Period" then
                FindUserPeriod('')
            else
                FindPeriod('');
        end;
    end;

    [Scope('OnPrem')]
    procedure ChangeVendVATInvoices(AskConfirmation: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrRec: Record "VAT Document Entry Buffer";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
    begin
        CurrRec := Rec;
        SetRange("Changed Vendor VAT Invoice", true);
        if not IsEmpty and AskConfirmation then
            if not Confirm(StrSubstNo(Text003, FieldCaption("Changed Vendor VAT Invoice")), true) then
                exit;
        if FindSet(true) then
            repeat
                VendLedgEntry.Get("Entry No.");
                VendEntryEdit.UpdateVATInvoiceData(
                  VendLedgEntry,
                  "Vendor VAT Invoice No.",
                  "Vendor VAT Invoice Date",
                  "Vendor VAT Invoice Rcvd Date");
                SetChangedVATInvoice();
                Modify();
            until Next() = 0;
        SetRange("Changed Vendor VAT Invoice");
        Rec := CurrRec;
        CurrPage.Update(false);
    end;

    local procedure TypeOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    [Scope('OnPrem')]
    procedure CalcVATAmount()
    begin
        CalcFields("VAT Amount To Allocate");
        if "Allocated VAT Amount" <> "VAT Amount To Allocate" then
            "Allocated VAT Amount" := "VAT Amount To Allocate";
    end;
}

