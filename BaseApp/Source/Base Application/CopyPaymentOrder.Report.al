report 11702 "Copy Payment Order"
{
    Caption = 'Copy Payment Order';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of issued payment order.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            IssuedPmtOrdHdr: Record "Issued Payment Order Header";
                        begin
                            if IssuedPmtOrdHdr.Get(DocNo) then;
                            if PAGE.RunModal(0, IssuedPmtOrdHdr) = ACTION::LookupOK then
                                DocNo := IssuedPmtOrdHdr."No.";
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        BankStmtLn: Record "Bank Statement Line";
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
        LineNo: Integer;
    begin
        if DocNo = '' then
            Error(DocNoErr);

        BankStmtLn.LockTable;
        BankStmtLn.SetRange("Bank Statement No.", BankStmtHdr."No.");
        if BankStmtLn.FindLast then
            LineNo := BankStmtLn."Line No.";

        IssuedPmtOrdLn.SetRange("Payment Order No.", DocNo);
        if IssuedPmtOrdLn.FindSet then
            repeat
                LineNo += 10000;
                BankStmtLn.Init;
                BankStmtLn.Validate("Bank Statement No.", BankStmtHdr."No.");
                BankStmtLn."Line No." := LineNo;
                BankStmtLn.Description := IssuedPmtOrdLn.Description;
                BankStmtLn."Account No." := IssuedPmtOrdLn."Account No.";
                BankStmtLn."Variable Symbol" := IssuedPmtOrdLn."Variable Symbol";
                BankStmtLn."Constant Symbol" := IssuedPmtOrdLn."Constant Symbol";
                BankStmtLn."Specific Symbol" := IssuedPmtOrdLn."Specific Symbol";
                BankStmtLn.Validate(Amount, -IssuedPmtOrdLn.Amount);
                BankStmtLn."Transit No." := IssuedPmtOrdLn."Transit No.";
                BankStmtLn.IBAN := IssuedPmtOrdLn.IBAN;
                BankStmtLn."SWIFT Code" := IssuedPmtOrdLn."SWIFT Code";
                BankStmtLn.Insert;
            until IssuedPmtOrdLn.Next = 0;
    end;

    var
        BankStmtHdr: Record "Bank Statement Header";
        DocNo: Code[20];
        DocNoErr: Label 'Enter Document No.';

    [Scope('OnPrem')]
    procedure SetBankStmtHdr(NewBankStmtHdr: Record "Bank Statement Header")
    begin
        BankStmtHdr := NewBankStmtHdr;
    end;
}

