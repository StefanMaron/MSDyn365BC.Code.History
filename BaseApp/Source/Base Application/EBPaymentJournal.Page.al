page 2000001 "EB Payment Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'EB Payment Journals';
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Request Approval';
    SaveValues = true;
    SourceTable = "Payment Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the batch name of the payment journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DoLookup := PmtJrnlMgt.LookupName(GetRangeMax("Journal Template Name"), CurrentJnlBatchName, Text);
                        CurrPage.Update();
                        exit(DoLookup);
                    end;

                    trigger OnValidate()
                    begin
                        PmtJrnlMgt.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali;
                    end;
                }
                field(BankAccountCodeFilter; BankAccountCodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    Lookup = true;
                    ToolTip = 'Specifies the bank account from which the payment is made.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BankAccList: Page "Bank Account List";
                    begin
                        BankAccList.LookupMode(true);
                        if not (BankAccList.RunModal = ACTION::LookupOK) then
                            exit(false);

                        Text := BankAccList.GetSelectionFilter;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        BankAccountCodeFilterOnAfterVa;
                    end;
                }
                field(ExportProtocolCode; ExportProtocolCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocol';
                    Lookup = true;
                    TableRelation = "Export Protocol".Code;
                    ToolTip = 'Specifies the payment journal line export protocol code, which controls what payment file will be generated in the payment journal.';

                    trigger OnValidate()
                    begin
                        ExportProtocolCodeOnAfterValid;
                        GetExportProtocol;
                        EnablePaymentExportErrors := ExportProtocol."Export Object Type" = ExportProtocol."Export Object Type"::XMLPort;
                        EnableCheckPaymentLines := not EnablePaymentExportErrors;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Export Protocol Code"; "Export Protocol Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the protocol to use for exporting the payment history.';
                }
                field("Separate Line"; "Separate Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment message is formatted using separate lines.';
                }
                field("ISO Currency Code"; "ISO Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ISO code that defines the currency associated with the payment journal entry.';
                }
                field("Standard Format Message"; "Standard Format Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the message in the Payment Message field is a standard format message or not.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you want the payment to be posted.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor number that the entry on the journal line will be posted to.';

                    trigger OnValidate()
                    begin
                        PmtJrnlMgt.GetAccount(Rec, AccName, BankAccName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Payment Message"; "Payment Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment message that is to be included in this payment.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outstanding amount.';
                }
                field("Pmt. Disc. Possible"; "Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount that is subtracted from the remaining amount of the outstanding entry.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the payment.';
                    Visible = true;
                }
                field("Currency Factor"; "Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency exchange factor that is based on the date of the payment.';
                    Visible = false;
                }
                field("Bank Account"; "Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that the payment will be posted to.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Beneficiary Bank Account"; "Beneficiary Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank account.';
                }
                field("Beneficiary Bank Account No."; "Beneficiary Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the payment will be posted to.';
                }
                field("Beneficiary IBAN"; "Beneficiary IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the International Bank Account Number (IBAN) for the recipient of the payment.';
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code for the bank account that the payment is made from.';
                }
                field("Bank Country/Region Code"; "Bank Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region code of the bank account.';
                }
                field("Instruction Priority"; "Instruction Priority")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order of importance for processing the payment.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("IBLC/BLWI Code"; "IBLC/BLWI Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBLC/BLWI code, regarding the kind of payment.';
                    Visible = false;
                }
                field("IBLC/BLWI Justification"; "IBLC/BLWI Justification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBLC/BLWI justification, describing the kind of payment.';
                    Visible = false;
                }
                field("Code Payment Method"; "Code Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify the payment method.';
                    Visible = false;
                }
                field("Code Expenses"; "Code Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code expense that was defined in the export protocol.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the export protocol that is associated with the payment journal.';
                }
            }
            group(Control60)
            {
                ShowCaption = false;
                fixed(Control1901775801)
                {
                    ShowCaption = false;
                    group("Bank Account Name")
                    {
                        Caption = 'Bank Account Name';
                        field(BankAccName; BankAccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                        }
                    }
                    group("Remittee Name")
                    {
                        Caption = 'Remittee Name';
                        field(AccName; AccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Remittee Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the customer or vendor who has been entered on the payment journal.';
                        }
                    }
                    group("Total Remittee (LCY)")
                    {
                        Caption = 'Total Remittee (LCY)';
                        field(BalanceRem; (Balance + "Amount (LCY)" - xRec."Amount (LCY)"))
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Remittee (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the payments of the customer or vendor that has been entered on the payment journal line.';
                            Visible = BalanceRemVisible;
                        }
                    }
                    group("Total Balance (LCY)")
                    {
                        Caption = 'Total Balance (LCY)';
                        field(TotalBalance; (TotalBalance + "Amount (LCY)" - xRec."Amount (LCY)"))
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Balance (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total balance in the payment journal.';
                            Visible = TotalBalanceVisible;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part("Payment File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment File Errors';
                Enabled = EnablePaymentExportErrors;
                SubPageLink = "Journal Template Name" = FIELD("Journal Template Name"),
                              "Journal Batch Name" = FIELD("Journal Batch Name"),
                              "Journal Line No." = FIELD("Line No.");
            }
            part(Control1900919607; "Dimension Set Entries FactBox")
            {
                ApplicationArea = Dimensions;
                SubPageLink = "Dimension Set ID" = FIELD("Dimension Set ID");
                Visible = false;
            }
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SaveRecord;
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PmtJrnlMgt.ShowCard(Rec);
                    end;
                }
                action(LedgerEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    Promoted = false;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        PmtJrnlMgt.ShowEntries(Rec);
                    end;
                }
            }
            group("Pay&ment")
            {
                Caption = 'Pay&ment';
                action(SuggestVendorPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Vendor Payments...';
                    Image = SuggestVendorPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create payment suggestions as lines in the payment journal.';

                    trigger OnAction()
                    begin
                        SuggestPayments.SetJournal(Rec);
                        SuggestPayments.RunModal();
                        Clear(SuggestPayments);
                    end;
                }
                action(CheckPaymentLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check Payment Lines';
                    Enabled = EnableCheckPaymentLines;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Test the payment journal lines to validate the payment journal lines. The validation that is performed on the journal lines depends on the type of check that is specified in the Export Protocols window.';

                    trigger OnAction()
                    begin
                        GetExportProtocol;
                        if ExportProtocol.CheckPaymentLines(Rec) then
                            Message(Text002);
                    end;
                }
                action(ExportPaymentLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Payment Lines';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Export the payments to a file. An export protocol defines the payment file format that you want to use for the electronic banking payments. Each journal line contains all the information needed for payment of an outstanding entry.';

                    trigger OnAction()
                    begin
                        GetExportProtocol;
                        ExportProtocol.ExportPaymentLines(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PmtJrnlMgt.GetAccount(Rec, AccName, BankAccName);
        UpdateAmount;
    end;

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateAmount;
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceRemVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PmtJrnlMgt.SetUpNewLine(Rec, xRec);
        Clear(ShortcutDimCode);
        Clear(AccName);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
        OpenedFromBatch: Boolean;
        IsHandled: Boolean;
    begin
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Journal Template Name" = '');
        EnablePaymentExportErrors := false;
        EnableCheckPaymentLines := true;
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            PmtJrnlMgt.OpenJournal(CurrentJnlBatchName, Rec);
            exit;
        end;

        IsHandled := false;
        OnOpenPageOnBeforeTemplateSelection(Rec, PmtJrnlMgt, CurrentJnlBatchName, IsHandled);
        if not IsHandled then begin
            PmtJrnlMgt.TemplateSelection(Rec, JnlSelected);
            if not JnlSelected then
                Error('');
        end;
        PmtJrnlMgt.OpenJournal(CurrentJnlBatchName, Rec);
        ClearVariables();
    end;

    var
        ExportProtocol: Record "Export Protocol";
        SuggestPayments: Report "Suggest Vendor Payments EB";
        PmtJrnlMgt: Codeunit PmtJrnlManagement;
        CurrentJnlBatchName: Code[10];
        AccName: Text[100];
        BankAccName: Text[100];
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
        DoLookup: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        Text001: Label 'Please set an Export Protocol filter on the payment journal.';
        Text002: Label 'Payment lines have been validated successfully.';
        [InDataSet]
        BalanceRemVisible: Boolean;
        [InDataSet]
        TotalBalanceVisible: Boolean;
        EnablePaymentExportErrors: Boolean;
        EnableCheckPaymentLines: Boolean;

    protected var
        ExportProtocolCode: Code[20];
        BankAccountCodeFilter: Code[1024];

    local procedure UpdateAmount()
    begin
        PmtJrnlMgt.CalculateTotals(Rec, xRec, Balance, TotalBalance, ShowAmount, ShowTotalAmount);
        BalanceRemVisible := ShowAmount;
        TotalBalanceVisible := ShowTotalAmount;
    end;

    procedure GetExportProtocol()
    begin
        if ExportProtocolCode = '' then
            Error(Text001);
        ExportProtocol.Get(ExportProtocolCode);
    end;

    local procedure BankAccountCodeFilterOnAfterVa()
    begin
        FilterGroup(2);
        SetFilter("Bank Account", BankAccountCodeFilter);
        FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        PmtJrnlMgt.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ExportProtocolCodeOnAfterValid()
    begin
        FilterGroup(2);
        SetFilter("Export Protocol Code", ExportProtocolCode);
        FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure ClearVariables()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearVariables(Rec, BankAccountCodeFilter, ExportProtocolCode, IsHandled);
        if IsHandled then
            exit;

        Clear(ExportProtocolCode);
        Clear(BankAccountCodeFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeTemplateSelection(var PaymentJournalLine: Record "Payment Journal Line"; var PmtJrnlMgt: Codeunit PmtJrnlManagement; var CurrentJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearVariables(var PaymentJournalLine: Record "Payment Journal Line"; var BankAccountCodeFilter: Code[1024]; var ExportProtocolCode: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

