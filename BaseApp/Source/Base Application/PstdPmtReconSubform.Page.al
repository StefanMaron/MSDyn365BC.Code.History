page 1296 "Pstd. Pmt. Recon. Subform"
{
    AutoSplitKey = true;
    Caption = 'Posted Payment Reconciliation Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Payment Recon. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                FreezeColumn = Difference;
                ShowCaption = false;
                field("Transaction Date"; "Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment represented by the journal line was recorded in the bank account.';
                }
                field("Transaction ID"; "Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the posted payment reconciliation. ';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the posted payment.';
                }
                field("Statement Amount"; "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on the bank transaction that represents the posted payment.';
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that was applied to the related invoice or credit memo before this payment was posted.';
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the Applied Amount field.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account that the payment was posted to.';
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the payment was posted to.';
                }
                field("Applied Entries"; "Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which customer or vendor ledger entries were applied in relation to posting the payment.';
                    Visible = false;
                }
                field("Related-Party Name"; "Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about the customer or vendor that the posted payment was for.';
                    Visible = false;
                }
                field("Additional Transaction Info"; "Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about the transaction as recorded on the bank statement line.';
                    Visible = false;
                }
                field("Applied Document No."; "Applied Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the payment is applied to.';

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                        GLEntry: Record "G/L Entry";
                        FilterValue: Text;
                    begin
                        if "Applied Document No." <> '' then begin
                            FilterValue := ConvertStr("Applied Document No.", ',', '|');
                            case "Account Type" of
                                "Account Type"::Customer:
                                    begin
                                        CustLedgerEntry.SetFilter("Document No.", FilterValue);
                                        PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgerEntry);
                                    end;
                                "Account Type"::Vendor:
                                    begin
                                        VendorLedgerEntry.SetFilter("Document No.", FilterValue);
                                        PAGE.RunModal(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
                                    end;
                                // NAVCZ
                                "Account Type"::"G/L Account":
                                    begin
                                        GLEntry.SetFilter("Document No.", FilterValue);
                                        PAGE.RunModal(PAGE::"General Ledger Entries", GLEntry);
                                    end;
                            // NAVCZ
                            end;
                        end;
                    end;
                }
                field("Specific Symbol"; "Specific Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detail information for payment.';
                }
                field("Constant Symbol"; "Constant Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional symbol of bank payments.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the external document number of vendor.';
                }
            }
        }
    }

    actions
    {
    }
}

