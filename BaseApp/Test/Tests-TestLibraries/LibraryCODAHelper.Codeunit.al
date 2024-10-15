codeunit 143001 "Library - CODA Helper"
{

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account")
    var
        Customer: Record Customer;
        CODAStatementLine: Record "CODA Statement Line";
    begin
        // Create a Customer
        LibrarySales.CreateCustomer(Customer);

        // Create a CustomerBankAccount
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        with CustomerBankAccount do begin
            "Bank Account No." :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Bank Account No.")), 1, MaxStrLen("Bank Account No."));
            IBAN :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CODAStatementLine."Bank Account No. Other Party")), 1, MaxStrLen(IBAN));
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
        CODAStatementLine: Record "CODA Statement Line";
    begin
        // Cretae a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // Create a VendorBankAccount
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        with VendorBankAccount do begin
            "Bank Account No." :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Bank Account No.")), 1, MaxStrLen("Bank Account No."));
            IBAN :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(CODAStatementLine."Bank Account No. Other Party")), 1, MaxStrLen(IBAN));
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCODAStatement(var CODAStatement: Record "CODA Statement"; BankAccountNo: Text[20])
    begin
        CODAStatement.Init();
        CODAStatement."Bank Account No." := BankAccountNo;
        CODAStatement."Statement No." := Format(LibraryRandom.RandInt(10));
        CODAStatement."Statement Date" := WorkDate();
        CODAStatement.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateCODAStatementLine(var CODAStatementLine: Record "CODA Statement Line"; CODAStatement: Record "CODA Statement"; BankAccountNoOtherParty: Text[34]; AccountType: Option)
    var
        TransactionCoding: Record "Transaction Coding";
    begin
        CreateTransactionCoding(TransactionCoding, AccountType);
        with CODAStatementLine do begin
            "Bank Account No." := CODAStatement."Bank Account No.";
            "Statement No." := CODAStatement."Statement No.";
            "Transaction Family" := TransactionCoding."Transaction Family";
            Transaction := TransactionCoding.Transaction;
            "Transaction Category" := TransactionCoding."Transaction Category";
            "Bank Account No. Other Party" := BankAccountNoOtherParty;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTransactionCoding(var TransactionCoding: Record "Transaction Coding"; AccountType: Option)
    begin
        with TransactionCoding do begin
            "Transaction Family" := LibraryRandom.RandInt(99);
            Transaction := LibraryRandom.RandInt(99);
            "Transaction Category" := LibraryRandom.RandInt(999);
            "Account Type" := AccountType;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessCODABankStmtLine(CODAStatementLine: Record "CODA Statement Line")
    var
        PostCodedBankStatement: Codeunit "Post Coded Bank Statement";
    begin
        PostCodedBankStatement.InitCodeunit(false, false);
        PostCodedBankStatement.ProcessCodBankStmtLine(CODAStatementLine);
    end;
}

