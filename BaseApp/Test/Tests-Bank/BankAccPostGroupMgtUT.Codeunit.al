codeunit 134237 "Bank Acc. Post. Group Mgt. UT"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The object will be removed with obsoleted field G/L Bank Account No.';
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Bank Account]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_Validate_GLAccountNo()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Validate_GLAccountNo(BankAccountPostingGroup);
        Validate_GLAccountNo(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_Validate_GLBankAccountNo()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Validate_GLBankAccountNo(BankAccountPostingGroup);
        Validate_GLBankAccountNo(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnInsert1()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Insert_Case_1(BankAccountPostingGroup);
        Insert_Case_1(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnInsert2()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Insert_Case_2(BankAccountPostingGroup);
        Insert_Case_2(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnInsert4()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Insert_Case_4(BankAccountPostingGroup);
        Insert_Case_4(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnModify1()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Modify_Case_1(BankAccountPostingGroup);
        Modify_Case_1(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnModify2()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Modify_Case_2(BankAccountPostingGroup);
        Modify_Case_2(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnModify4()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Modify_Case_4(BankAccountPostingGroup);
        Modify_Case_4(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnModify5()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Modify_Case_5(BankAccountPostingGroup);
        Modify_Case_5(TempBankAccountPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountFieldSyncInBankAccountPostingGroup_OnModify6()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        TempBankAccountPostingGroup: Record "Bank Account Posting Group" temporary;
    begin
        Modify_Case_6(BankAccountPostingGroup);
        Modify_Case_6(TempBankAccountPostingGroup);
    end;

    local procedure Validate_GLAccountNo(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
    end;

    local procedure Validate_GLBankAccountNo(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Validate("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
    end;

    local procedure Insert_Case_1(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup."G/L Bank Account No." := GLAccount."No.";
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Insert();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Insert_Case_2(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Insert();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Insert_Case_4(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Insert();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", '');
        BankAccountPostingGroup.TestField("G/L Account No.", '');
        BankAccountPostingGroup.Delete();
    end;

    local procedure Modify_Case_1(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Insert();

        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Modify();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Modify_Case_2(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Insert();

        BankAccountPostingGroup."G/L Bank Account No." := GLAccount."No.";
        BankAccountPostingGroup.Modify();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Modify_Case_4(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Bank Account No." := '';
        BankAccountPostingGroup."G/L Account No." := '';
        BankAccountPostingGroup.Insert();

        BankAccountPostingGroup."G/L Bank Account No." := GLAccount."No.";
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Modify();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Modify_Case_5(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
        GLAccountOther: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccountOther);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Bank Account No." := GLAccountOther."No.";
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Insert();

        BankAccountPostingGroup."G/L Bank Account No." := GLAccount."No.";
        BankAccountPostingGroup.Modify();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccount."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Delete();
    end;

    local procedure Modify_Case_6(var BankAccountPostingGroup: Record "Bank Account Posting Group")
    var
        GLAccount: Record "G/L Account";
        GLAccountOther: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccountOther);

        BankAccountPostingGroup.Code := LibraryUtility.GenerateGUID();
        BankAccountPostingGroup."G/L Bank Account No." := GLAccountOther."No.";
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Insert();

        BankAccountPostingGroup."G/L Account No." := GLAccountOther."No.";
        BankAccountPostingGroup.Modify();
        BankAccountPostingGroup.TestField("G/L Bank Account No.", GLAccountOther."No.");
        BankAccountPostingGroup.TestField("G/L Account No.", GLAccountOther."No.");
        BankAccountPostingGroup.Delete();
    end;
}

