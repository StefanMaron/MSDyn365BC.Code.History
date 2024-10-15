page 12175 "Customer Bill Card"
{
    Caption = 'Customer Bill Card';
    PageType = Document;
    SourceTable = "Customer Bill Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the bill header you are setting up.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the account number of the bank that is managing the customer bills.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment method code for the customer bills that is entered in the Customer Card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you want the bill header to be issued.';
                }
                field("List Date"; "List Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the bill is created.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the bank receipt that is applied to the customer bill.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer bill is of type person or company.';
                }
            }
            part(CustomerBillLine; "Subform Customer Bill Line")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Customer Bill No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code from the transaction entry.';
                }
                field("Report Header"; "Report Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a descriptive title for the report header.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901848907; "Customer Bill Information")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = CustomerBillLine;
                SubPageLink = "Journal Template Name" = CONST(''),
                              "Journal Batch Name" = CONST('12174'),
                              "Journal Line No." = FIELD("Line No."),
                              "Document No." = FIELD("Customer Bill No.");
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
                action(SuggestCustomerBill)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Customer Bill';
                    Ellipsis = true;
                    Image = SuggestCustomerBill;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Generate a customer bill based on the current information.';

                    trigger OnAction()
                    begin
                        TestField("Payment Method Code");
                        TestField("Bank Account No.");

                        GetBillCode;

                        Clear(SuggestCustomerBill);
                        SuggestCustomerBill.InitValues(Rec, Bill."Allow Issue");
                        SuggestCustomerBill.RunModal;
                    end;
                }
                separator(Action1130009)
                {
                }
                action("Recall Customer Bill")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recall Customer Bill';
                    Image = ReturnCustomerBill;
                    RunObject = Codeunit "Recall Customer Bill";
                    ToolTip = 'Recall an existing customer bill.';
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Print a test report for the document.';

                    trigger OnAction()
                    begin
                        CustomerBillLine.SetRange("Customer Bill No.", "No.");
                        CustomerBillLine.SetRange(Amount, 0);
                        if CustomerBillLine.FindFirst then
                            Error(Text1130004,
                              CustomerBillLine."Line No.",
                              CustomerBillLine.FieldCaption(Amount));

                        "Test Report" := true;
                        Modify;
                        Commit;
                        SetRecFilter;
                        REPORT.RunModal(REPORT::"List of Bank Receipts", true, false, Rec);
                        SetRange("No.");
                    end;
                }
                action("Post and Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "Customer Bill - Post + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post the document and also print it.';
                }
            }
        }
        area(reporting)
        {
            action(ExportBillToFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Bill to File';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Export the document.';

                trigger OnAction()
                begin
                    ExportToFile;
                end;
            }
            action("List of Bank Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'List of Bank Receipts';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "List of Bank Receipts";
                ToolTip = 'View the related list of bank receipts.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CalcBalance;
    end;

    var
        Bill: Record Bill;
        CustomerBillLine: Record "Customer Bill Line";
        SuggestCustomerBill: Report "Suggest Customer Bills";
        Text1130004: Label 'Line %1 has %2 equal to 0.';
        Balance: Decimal;
        TotalPayments: Decimal;

    [Scope('OnPrem')]
    procedure GetBillCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get("Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");
    end;

    [Scope('OnPrem')]
    procedure CalcBalance()
    var
        BankAcc: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        BillPostingGroup: Record "Bill Posting Group";
        GLAcc: Record "G/L Account";
    begin
        if "Bank Account No." <> '' then begin
            BankAcc.Get("Bank Account No.");
            if Type <> Type::" " then begin
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
                if BillPostingGroup.Get("Bank Account No.", "Payment Method Code") then
                    case Type of
                        Type::"Bills For Collection":
                            begin
                                if BillPostingGroup."Bills For Collection Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills For Collection Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                        Type::"Bills For Discount":
                            begin
                                if BillPostingGroup."Bills For Discount Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills For Discount Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                        Type::"Bills Subject To Collection":
                            begin
                                if BillPostingGroup."Bills Subj. to Coll. Acc. No." <> '' then
                                    GLAcc.Get(BillPostingGroup."Bills Subj. to Coll. Acc. No.");

                                GLAcc.CalcFields(Balance);
                                Balance := GLAcc.Balance;
                            end;
                    end;
            end;
            CalcFields("Total Amount");
            TotalPayments := "Total Amount";
        end else begin
            TotalPayments := 0;
            Balance := 0;
        end;
    end;
}

