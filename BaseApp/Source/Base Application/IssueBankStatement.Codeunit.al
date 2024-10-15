codeunit 11702 "Issue Bank Statement"
{
    Permissions = TableData "Issued Bank Statement Header" = im,
                  TableData "Issued Bank Statement Line" = im;
    TableNo = "Bank Statement Header";

    trigger OnRun()
    var
        BankStmtLine: Record "Bank Statement Line";
        IssuedBankStmtHeader: Record "Issued Bank Statement Header";
        IssuedBankStmtLine: Record "Issued Bank Statement Line";
        BankAccount: Record "Bank Account";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        TestField("Bank Account No.");
        TestField("Document Date");
        BankAccount.Get("Bank Account No.");
        BankAccount.TestField(Blocked, false);

        with IssuedBankStmtHeader do begin
            SetRange("Bank Account No.", Rec."Bank Account No.");
            SetRange("External Document No.", Rec."External Document No.");
            if BankAccount."Check Ext. No. by Current Year" then
                SetRange("Document Date", CalcDate('<CY>-<1Y>+<1D>', Rec."Document Date"),
                  CalcDate('<CY>', Rec."Document Date"));
            if not IsEmpty then begin
                FindFirst;
                Error(AlreadyExistErr, FieldCaption("External Document No."), TableCaption, FieldCaption("No."), "No.");
            end;
            Reset;
        end;

        BankStmtLine.LockTable();
        if BankStmtLine.FindLast then;

        BankStmtLine.SetRange("Bank Statement No.", "No.");
        if not BankStmtLine.FindSet then
            Error(NothingToIssueErr);
        repeat
            BankStmtLine.TestField(Amount);
        until BankStmtLine.Next = 0;

        // insert header;
        IssuedBankStmtHeader.Init();
        IssuedBankStmtHeader.TransferFields(Rec);
        BankAccount.TestField("Issued Bank Statement Nos.");
        if BankAccount."Issued Bank Statement Nos." <> "No. Series" then
            IssuedBankStmtHeader."No." := NoSeriesMgt.GetNextNo(BankAccount."Issued Bank Statement Nos.", "Document Date", true);

        "Last Issuing No." := IssuedBankStmtHeader."No.";

        IssuedBankStmtHeader."Pre-Assigned No. Series" := "No. Series";
        IssuedBankStmtHeader."Pre-Assigned No." := "No.";
        IssuedBankStmtHeader."Pre-Assigned User ID" := "User ID";
        IssuedBankStmtHeader."User ID" := UserId;
        IssuedBankStmtHeader.Insert();

        // insert lines
        if BankStmtLine.Find('-') then
            repeat
                IssuedBankStmtLine.Init();
                IssuedBankStmtLine.TransferFields(BankStmtLine);
                IssuedBankStmtLine."Bank Statement No." := IssuedBankStmtHeader."No.";
                IssuedBankStmtLine.Insert();
            until BankStmtLine.Next = 0;

        // delete non issued bank statement;
        Delete(true);
    end;

    var
        ErrorText: array[1000] of Text;
        AlreadyExistErr: Label 'The %1 field allready exist in table %2, field %3 = %4.', Comment = '%1=External Document No. field caption; %2=Issue Bank Stmt Header table caption; %3=No. field caption; %4= No.';
        NothingToIssueErr: Label 'There is nothing to issue.';
        CustVendIsBlockedErr: Label '%1 %2 is Blocked.', Comment = '%1=table caption; %2=No.';
        PrivacyBlockedErr: Label '%1 %2 is blocked for privacy.', Comment = '%1=table caption; %2=No.';

    [Scope('OnPrem')]
    procedure CheckBankStatementLine(IssuedBankStmtLine: Record "Issued Bank Statement Line"; CauseError: Boolean; AddError: Boolean) ReturnValue: Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        ReturnValue := true;
        if IssuedBankStmtLine."No." <> '' then
            case IssuedBankStmtLine.Type of
                IssuedBankStmtLine.Type::Customer:
                    begin
                        Customer.Get(IssuedBankStmtLine."No.");
                        if Customer."Privacy Blocked" then begin
                            if CauseError then
                                Customer.FieldError("Privacy Blocked");
                            ReturnValue := false;
                            if AddError then
                                AddErrorText(StrSubstNo(PrivacyBlockedErr, Customer.TableCaption, Customer."No."));
                        end;
                        if Customer.Blocked in [Customer.Blocked::All] then begin
                            if CauseError then
                                Customer.FieldError(Blocked);
                            ReturnValue := false;
                            if AddError then
                                AddErrorText(StrSubstNo(CustVendIsBlockedErr, Customer.TableCaption, Customer."No."));
                        end;
                    end;
                IssuedBankStmtLine.Type::Vendor:
                    begin
                        Vendor.Get(IssuedBankStmtLine."No.");
                        if Vendor."Privacy Blocked" then begin
                            if CauseError then
                                Vendor.FieldError("Privacy Blocked");
                            ReturnValue := false;
                            if AddError then
                                AddErrorText(StrSubstNo(PrivacyBlockedErr, Vendor.TableCaption, Vendor."No."));
                        end;

                        if Vendor.Blocked in [Vendor.Blocked::All] then begin
                            if CauseError then
                                Vendor.FieldError(Blocked);
                            ReturnValue := false;
                            if AddError then
                                AddErrorText(StrSubstNo(CustVendIsBlockedErr, Vendor.TableCaption, Vendor."No."));
                        end;
                    end;
            end;
    end;

    local procedure AddErrorText(NewText: Text)
    begin
        ErrorText[CompressArray(ErrorText) + 1] := NewText;
    end;

    [Scope('OnPrem')]
    procedure ReturnError(var ErrorText2: Text; NumberNo: Integer)
    begin
        ErrorText2 := ErrorText[NumberNo];
    end;
}

