page 10141 "Deposit Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type from which the deposit was received.';

                    trigger OnValidate()
                    var
                        CurType: Integer;
                    begin
                        if xRec."Account Type" <> "Account Type" then begin
                            CurType := "Account Type";
                            Init;
                            CopyValuesFromHeader;
                            "Account Type" := CurType;
                        end;
                        AccountTypeOnAfterValidate;
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the entity from which the deposit item was received.';

                    trigger OnValidate()
                    begin
                        // special case:  OnValidate for Account No. field changed the Currency code, now we must change it back.
                        DepositHeader.Reset();
                        DepositHeader.SetCurrentKey("Journal Template Name", "Journal Batch Name");
                        DepositHeader.SetRange("Journal Template Name", "Journal Template Name");
                        DepositHeader.SetRange("Journal Batch Name", "Journal Batch Name");
                        if DepositHeader.FindFirst then begin
                            Validate("Currency Code", DepositHeader."Currency Code");
                            Validate("Posting Date", DepositHeader."Posting Date");
                        end;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the deposit line.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that the deposit is related to.';

                    trigger OnValidate()
                    begin
                        if not ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund]) then
                            error(DocumentTypeErr);
                    end;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the deposit document.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a debit entry if the value in the Amount field is positive. A negative amount indicates a corrective entry.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Credit Amount"; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the credit entries in the deposit.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the item, such as a check, that was deposited.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
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
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that will be applied to the deposit process.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number that will be applied to the deposit process.';
                    Visible = false;
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry ID that will be applied to the deposit process.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a reason code that will enable you to trace the entry. The reason code to all G/L, bank account, customer and other ledger entries created when posting.';
                    Visible = false;
                }
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
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded. ';

                    trigger OnAction()
                    begin
                        ShowApplyEntries;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(AccountCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account &Card';
                    Image = Account;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountCard;
                    end;
                }
                action(AccountLedgerEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Ledger E&ntries';
                    Image = LedgerEntries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View ledger entries that are posted for the account on the deposit line.';

                    trigger OnAction()
                    begin
                        ShowAccountLedgerEntries;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensionEntries;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if "Journal Template Name" <> '' then begin
            "Account Type" := xRec."Account Type";
            "Document Type" := xRec."Document Type";
            Clear(ShortcutDimCode);
            CopyValuesFromHeader;
        end;
    end;

    var
        DepositHeader: Record "Deposit Header";
        GenJnlShowCard: Codeunit "Gen. Jnl.-Show Card";
        GenJnlShowEntries: Codeunit "Gen. Jnl.-Show Entries";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        ShortcutDimCode: array[8] of Code[20];
        DocumentTypeErr: Label 'Document Type should be Payment or Refund.';

    local procedure CopyValuesFromHeader()
    var
        DepositHeader: Record "Deposit Header";
    begin
        DepositHeader.SetCurrentKey("Journal Template Name", "Journal Batch Name");
        DepositHeader.SetRange("Journal Template Name", "Journal Template Name");
        DepositHeader.SetRange("Journal Batch Name", "Journal Batch Name");
        DepositHeader.FindFirst;
        "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
        "Bal. Account No." := DepositHeader."Bank Account No.";
        "Currency Code" := DepositHeader."Currency Code";
        "Currency Factor" := DepositHeader."Currency Factor";
        Validate("Posting Date", DepositHeader."Posting Date");
        "External Document No." := DepositHeader."No.";
        "Reason Code" := DepositHeader."Reason Code";
    end;

    procedure ShowAccountCard()
    begin
        GenJnlShowCard.Run(Rec);
    end;

    procedure ShowAccountLedgerEntries()
    begin
        GenJnlShowEntries.Run(Rec);
    end;

    procedure ShowApplyEntries()
    begin
        Clear(GenJnlApply);
        GenJnlApply.Run(Rec);
    end;

    procedure ShowDimensionEntries()
    begin
        ShowDimensions;
    end;

    local procedure AccountTypeOnAfterValidate()
    begin
        if "Account Type" = "Account Type"::Vendor then
            "Document Type" := "Document Type"::Refund
        else
            "Document Type" := "Document Type"::Payment;
    end;
}

