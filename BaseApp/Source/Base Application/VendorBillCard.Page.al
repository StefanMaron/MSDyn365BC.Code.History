page 12185 "Vendor Bill Card"
{
    Caption = 'Vendor Bill Card';
    PageType = Document;
    SourceTable = "Vendor Bill Header";
    SourceTableView = WHERE("List Status" = CONST(Open));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        AssistEdit(xRec);
                    end;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the vendor bills and bank transfers.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the vendor bills that is entered in the Vendor Card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you want the bill header to be posted.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created .';
                }
                field("Beneficiary Value Date"; "Beneficiary Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the transferred funds from vendor bill are available for use by the vendor.';
                }
                field("Bank Expense"; "Bank Expense")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any expenses or fees that are charged by the bank for the bank transfer.';
                }
                field("Total Amount"; "Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the sum of the amounts in the Amount field on the associated lines.';
                }
            }
            part(VendorBillLines; "Subform Vendor Bill Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Vendor Bill List No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for the vendor bill.';
                }
                field("Report Header"; "Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the amounts on the bill lines.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Vend. Bill")
            {
                Caption = '&Vend. Bill';
                Image = VendorBill;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = FIELD("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestPayment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Payment';
                    Ellipsis = true;
                    Image = SuggestVendorPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Get a suggested payment.';

                    trigger OnAction()
                    begin
                        TestField("Payment Method Code");

                        if "List Status" = "List Status"::Sent then
                            Error(Text1130001,
                              FieldCaption("List Status"),
                              SelectStr(2, Text1130002));

                        Clear(SuggestPayment);
                        SuggestPayment.InitValues(Rec);
                        SuggestPayment.RunModal;
                    end;
                }
                action(InsertVendBillLineManual)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Vend. Bill Line Manual';
                    Image = ExpandDepositLine;
                    ToolTip = 'Manually add an entry line to an existing vendor bill and have the amount applied to withholding tax, social security, and payment amounts.';

                    trigger OnAction()
                    var
                        ManualVendPmtLine: Page "Manual vendor Payment Line";
                    begin
                        ManualVendPmtLine.SetVendBillNoAndDueDate("No.", "Posting Date");
                        ManualVendPmtLine.Run;
                    end;
                }
            }
            action("&Create List")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Create List';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Vend. Bill List-Change Status";
                ToolTip = 'Send bills to your vendor based on the current information.';
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the vendor bill.';

                trigger OnAction()
                begin
                    SetRecFilter;
                    REPORT.RunModal(REPORT::"Vendor Bill Report", true, false, Rec);
                    SetRange("No.");
                end;
            }
        }
        area(reporting)
        {
            action("Vendor Bill List")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Bill List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Vendor Bill Report";
                ToolTip = 'View the list of vendor bills.';
            }
        }
    }

    var
        SuggestPayment: Report "Suggest Vendor Bills";
        Text1130001: Label '%1 must be %2.';
        Text1130002: Label 'Open,Sent';
}

