page 5237 "Employee Ledger Entries"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Ledger Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "Employee Ledger Entry" = m;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "Employee Ledger Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s posting date.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the document type that the employee entry belongs to.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the employee entry''s document number.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the employee that the entry is linked to.';
                }
                field("Message to Recipient"; "Message to Recipient")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the message exported to the payment file when you use the Export Payments to File function in the Payment Journal window.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies a description of the employee entry.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment method that was used to make the payment that resulted in the entry.';
                }
                field("Original Amount"; "Original Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the original entry.';
                }
                field("Original Amt. (LCY)"; "Original Amt. (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that the entry originally consisted of, in LCY.';
                    Visible = false;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                    Visible = false;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Remaining Amt. (LCY)"; "Remaining Amt. (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the type of balancing account that is used for the entry.';
                    Visible = false;
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the number of the balancing account that is used for the entry.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field("Amount to Apply"; "Amount to Apply")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount to apply.';
                    Visible = false;
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("Applying Entry"; "Applying Entry")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies whether the entry will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("Exported to Payment File"; "Exported to Payment File")
                {
                    ApplicationArea = BasicHR;
                    Editable = true;
                    ToolTip = 'Specifies that the entry was created as a result of exporting a payment journal line.';
                    Visible = false;
                }
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment of the employee document.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
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
                action("Applied E&ntries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Applied Employee Entries";
                    RunPageOnRec = true;
                    Scope = Repeater;
                    ToolTip = 'View the ledger entries that have been applied to this record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Scope = Repeater;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Detailed Empl. Ledger Entries";
                    RunPageLink = "Employee Ledger Entry No." = FIELD("Entry No."),
                                  "Employee No." = FIELD("Employee No.");
                    RunPageView = SORTING("Employee Ledger Entry No.", "Posting Date");
                    Scope = Repeater;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of the all posted entries and adjustments related to a specific employee ledger entry';
                }
                action(Navigate)
                {
                    ApplicationArea = BasicHR;
                    Caption = '&Navigate';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                    trigger OnAction()
                    var
                        Navigate: Page Navigate;
                    begin
                        Navigate.SetDoc("Posting Date", "Document No.");
                        Navigate.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ActionApplyEntries)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    var
                        EmployeeLedgerEntry: Record "Employee Ledger Entry";
                        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                    begin
                        EmployeeLedgerEntry.Copy(Rec);
                        EmplEntryApplyPostedEntries.ApplyEmplEntryFormEntry(EmployeeLedgerEntry);
                        Rec := EmployeeLedgerEntry;
                        Get("Entry No.");
                        CurrPage.Update;
                    end;
                }
                separator(Action9)
                {
                }
                action(UnapplyEntries)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Unapply Entries';
                    Ellipsis = true;
                    Image = UnApply;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                    trigger OnAction()
                    var
                        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                    begin
                        EmplEntryApplyPostedEntries.UnApplyEmplLedgEntry("Entry No.");
                    end;
                }
                action(CreatePayment)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Create Payment';
                    Image = SuggestVendorPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create a payment journal based on the selected entries.';

                    trigger OnAction()
                    var
                        EmployeeLedgerEntry: Record "Employee Ledger Entry";
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlManagement: Codeunit GenJnlManagement;
                    begin
                        CurrPage.SetSelectionFilter(EmployeeLedgerEntry);
                        if CreateEmployeePayment.RunModal = ACTION::OK then begin
                            CreateEmployeePayment.MakeGenJnlLines(EmployeeLedgerEntry);
                            GetBatchRecord(GenJournalBatch);
                            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
                            Clear(CreateEmployeePayment);
                        end else
                            Clear(CreateEmployeePayment);
                    end;
                }
                action(ReverseTransaction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse Transaction';
                    Ellipsis = true;
                    Image = ReverseRegister;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'Reverse an erroneous employee ledger entry.';

                    trigger OnAction()
                    var
                        ReversalEntry: Record "Reversal Entry";
                    begin
                        Clear(ReversalEntry);
                        if Reversed then
                            ReversalEntry.AlreadyReversedEntry(TableCaption, "Entry No.");
                        if "Journal Batch Name" = '' then
                            ReversalEntry.TestFieldError;
                        TestField("Transaction No.");
                        ReversalEntry.ReverseTransaction("Transaction No.");
                    end;
                }
            }
        }
    }

    var
        CreateEmployeePayment: Page "Create Employee Payment";

    local procedure GetBatchRecord(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
    begin
        GenJournalTemplate.Reset();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        if GenJournalTemplate.FindFirst then
            JournalTemplateName := GenJournalTemplate.Name;

        JournalBatchName := CreateEmployeePayment.GetBatchNumber;

        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
    end;
}

