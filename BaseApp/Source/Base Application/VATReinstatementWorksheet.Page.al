page 14947 "VAT Reinstatement Worksheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Reinstatement Worksheet';
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
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::"Accounting Period" then
                            AccountingPerioPeriodTypeOnVal;
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate;
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid;
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate;
                    end;
                }
            }
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("""Unrealized VAT Amount"" - ""Realized VAT Amount"""; "Unrealized VAT Amount" - "Realized VAT Amount")
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
                field("Realized VAT Amount"; "Realized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Realized VAT Base"; "Realized VAT Base")
                {
                    Editable = false;
                    Visible = false;
                }
                field("Unrealized VAT Amount"; "Unrealized VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
                }
                field("Unrealized VAT Base"; "Unrealized VAT Base")
                {
                    Editable = false;
                    ToolTip = 'Specifies the unrealized base amount if you use unrealized VAT.';
                    Visible = false;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("CV No."; "CV No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the creditor or debitor.';
                }
                field("CV Name"; "CV Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the creditor or debitor.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Vendor VAT Invoice No."; "Vendor VAT Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related vendor VAT invoice number.';
                }
                field("Vendor VAT Invoice Date"; "Vendor VAT Invoice Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related vendor VAT invoice number.';
                }
                field("Vendor VAT Invoice Rcvd Date"; "Vendor VAT Invoice Rcvd Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Incl. VAT';
                    Editable = false;
                }
                field("Remaining Amt. (LCY)"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be paid, expressed in LCY.';
                }
                field("Transaction No."; "Transaction No.")
                {
                    ToolTip = 'Specifies the transaction''s entry number.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
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
                action("Ledger Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger Entry';
                    Image = VendorLedger;
                    Promoted = false;
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
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
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
                Promoted = true;
                PromotedCategory = Process;
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
                Promoted = true;
                PromotedCategory = Process;
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
                    Ellipsis = true;
                    Image = MakeOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'Use a function to insert document lines for VAT reinstatement. ';

                    trigger OnAction()
                    var
                        SuggestVATReinstLines: Report "Suggest VAT Reinst. Lines";
                    begin
                        SuggestVATReinstLines.RunModal;
                        SuggestVATReinstLines.GetBuffer(Rec);
                    end;
                }
                separator(Action1210010)
                {
                }
                action("&Copy Lines to Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Copy Lines to Journal';
                    Ellipsis = true;
                    Image = SelectLineToApply;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CopySelectionToJnl;
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

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc("Document Date", "Document No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PeriodType := PeriodType::Month;
        AmountType := AmountType::"Balance at Date";
        if PeriodType = PeriodType::"Accounting Period" then
            FindUserPeriod('')
        else
            FindPeriod('');
    end;

    var
        UserSetup: Record "User Setup";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        Text001: Label 'There is nothing to post.';

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodFormManagement: Codeunit PeriodFormManagement;
    begin
        if GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
            if not PeriodFormManagement.FindDate('+', Calendar, PeriodType) then
                PeriodFormManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodFormManagement.FindDate(SearchText, Calendar, PeriodType);
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
        PeriodFormManagement: Codeunit PeriodFormManagement;
    begin
        if UserSetup.Get(UserId) then begin
            SetRange("Date Filter", UserSetup."Allow Posting From", UserSetup."Allow Posting To");
            if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                SetRange("Date Filter", GetRangeMin("Date Filter"));
        end else begin
            if GetFilter("Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", GetFilter("Date Filter"));
                if not PeriodFormManagement.FindDate('+', Calendar, PeriodType) then
                    PeriodFormManagement.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodFormManagement.FindDate(SearchText, Calendar, PeriodType);
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
        VATEntries.RunModal;
    end;

    [Scope('OnPrem')]
    procedure CopySelectionToJnl()
    var
        LineToCopy: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        Filters: Record "VAT Document Entry Buffer";
        CurrRec: Record "VAT Document Entry Buffer";
        CopyToVATReinstJournal: Report "Copy to VAT Reinst. Journal";
    begin
        CurrRec := Rec;
        Filters.CopyFilters(Rec);
        CurrPage.SetSelectionFilter(Rec);
        if FindSet then
            repeat
                LineToCopy := Rec;
                LineToCopy.Insert();
            until Next = 0;
        Rec := CurrRec;
        Reset;
        CopyFilters(Filters);

        LineToCopy.Reset();
        LineToCopy.SetFilter("Type Filter", GetFilter("Type Filter"));
        LineToCopy.SetFilter("Date Filter", GetFilter("Date Filter"));
        VATEntry.SetFilter("VAT Bus. Posting Group", GetFilter("VAT Bus. Posting Group Filter"));
        VATEntry.SetFilter("VAT Prod. Posting Group", GetFilter("VAT Prod. Posting Group Filter"));
        if LineToCopy.IsEmpty then
            Error(Text001);
        CopyToVATReinstJournal.SetParameters(LineToCopy, VATEntry, LineToCopy.GetRangeMax("Date Filter"));
        CopyToVATReinstJournal.RunModal;
        LineToCopy.Reset();
        LineToCopy.DeleteAll();
    end;

    local procedure AccountingPerioPeriodTypOnPush()
    begin
        FindUserPeriod('');
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush;
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush;
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush;
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush;
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush;
    end;

    local procedure AccountingPerioPeriodTypeOnVal()
    begin
        AccountingPerioPeriodTypOnPush;
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush;
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush;
    end;
}

