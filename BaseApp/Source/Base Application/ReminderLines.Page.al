page 435 "Reminder Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Reminder Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the line type.';

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate;
                        NoOnAfterValidate;
                        SetShowMandatoryConditions
                    end;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = TypeIsGLAccount;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate;
                    end;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the customer ledger entry that this reminder line is for.';
                    Visible = false;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = TypeIsCustomerLedgerEntry;
                    ToolTip = 'Specifies the document type of the customer ledger entry this reminder line is for.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = TypeIsCustomerLedgerEntry;
                    ToolTip = 'Specifies the document number of the customer ledger entry this reminder line is for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupDocNo;
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of the customer ledger entry this reminder line is for.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies an entry description, based on the contents of the Type field.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = OriginalAmountEmphasize;
                    ToolTip = 'Specifies the original amount of the customer ledger entry that this reminder line is for.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = RemainingAmountEmphasize;
                    ToolTip = 'Specifies the remaining amount of the customer ledger entry this reminder line is for.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = AmountEmphasize;
                    ToolTip = 'Specifies the amount in the currency that is represented by the currency code on the reminder header.';
                }
                field("No. of Reminders"; "No. of Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Reminder Level';
                    ToolTip = 'Specifies a number that indicates the reminder level.';
                    Visible = false;
                }
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the reminder line.';
                    Visible = false;
                }
                field("Applies-to Document Type"; "Applies-to Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to Document No."; "Applies-to Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
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
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetShowMandatoryConditions;
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat;
        OriginalAmountOnFormat;
        RemainingAmountOnFormat;
        AmountOnFormat;
    end;

    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        OriginalAmountEmphasize: Boolean;
        [InDataSet]
        RemainingAmountEmphasize: Boolean;
        [InDataSet]
        AmountEmphasize: Boolean;
        TypeIsGLAccount: Boolean;
        TypeIsCustomerLedgerEntry: Boolean;

    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);

        if TransferExtendedText.ReminderCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord;
            TransferExtendedText.InsertReminderExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate then
            CurrPage.Update;
    end;

    local procedure TypeOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        if "Detailed Interest Rates Entry" then
            DescriptionIndent := 2;
        DescriptionEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure OriginalAmountOnFormat()
    begin
        OriginalAmountEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure RemainingAmountOnFormat()
    begin
        RemainingAmountEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure AmountOnFormat()
    begin
        AmountEmphasize := not "Detailed Interest Rates Entry";
    end;

    local procedure SetShowMandatoryConditions()
    begin
        TypeIsGLAccount := Type = Type::"G/L Account";
        TypeIsCustomerLedgerEntry := Type = Type::"Customer Ledger Entry"
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ReminderLine: Record "Reminder Line")
    begin
    end;
}

