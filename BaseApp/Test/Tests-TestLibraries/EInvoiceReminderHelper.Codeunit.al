codeunit 143017 "E-Invoice Reminder Helper"
{

    trigger OnRun()
    begin
    end;

    var
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        TestValueTxt: Label 'Test Value';
        EInvoiceSalesHelper: Codeunit "E-Invoice Sales Helper";

    [Scope('OnPrem')]
    procedure CreateReminder(): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        CreateReminderDoc(ReminderHeader);
        exit(IssueReminder(ReminderHeader."No."));
    end;

    [Scope('OnPrem')]
    procedure CreateReminderDoc(var ReminderHeader: Record "Reminder Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        HowManyLinesToCreate: Integer;
        LineNo: Integer;
        VATProdPostGroupCode: Code[20];
    begin
        CreateReminderHeader(ReminderHeader);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATProdPostGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        HowManyLinesToCreate := 1 + LibraryRandom.RandInt(5);
        CreateReminderLines(ReminderHeader."No.", HowManyLinesToCreate, VATProdPostGroupCode, LineNo);
    end;

    [Scope('OnPrem')]
    procedure IssueReminder(ReminderHeaderNo: Code[20]): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        ReminderHeader.SetRange("No.", ReminderHeaderNo);
        REPORT.Run(REPORT::"Issue Reminders", false, true, ReminderHeader);

        with IssuedReminderHeader do begin
            SetFilter("Pre-Assigned No.", ReminderHeaderNo);
            FindFirst();
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header")
    var
        ReminderTerms: Record "Reminder Terms";
        Customer: Record Customer;
    begin
        EInvoiceHelper.CreateCustomer(Customer);

        with ReminderHeader do begin
            Init();
            Validate("Customer No.", Customer."No.");
            ReminderTerms.FindFirst();
            Validate("Reminder Terms Code", ReminderTerms.Code);
            "Post Interest" := true;
            "Post Additional Fee" := true;
            "Your Reference" := TestValueTxt;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateReminderLines(ReminderHeaderNo: Code[20]; NoOfLines: Integer; VATProdPostGroupCode: Code[20]; var LineNo: Integer)
    var
        ReminderLine: Record "Reminder Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do
            with ReminderLine do begin
                Init();
                "Reminder No." := ReminderHeaderNo;
                LineNo := LineNo + 10000;
                "Line No." := LineNo;
                "VAT Prod. Posting Group" := VATProdPostGroupCode;
                Validate(Type, Type::"G/L Account");
                Validate("No.", CreateGLAccount(VATProdPostGroupCode));
                Description := TestValueTxt;
                Validate(Amount, LibraryRandom.RandInt(1000));
                Insert(true);
            end;
    end;

    local procedure CreateGLAccount(VATProdPostGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup."Auto Insert Default" := false;
        GenProductPostingGroup.Modify();

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostGroupCode;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateReminderWithVATGroups(var ReminderHeader: Record "Reminder Header"; VATRate: array[5] of Decimal): Code[20]
    var
        VATProdPostingGroupCode: Code[20];
        NoOfLines: Integer;
        i: Integer;
        LineNo: Integer;
    begin
        CreateReminderHeader(ReminderHeader);
        LineNo := 0;
        for i := 1 to ArrayLen(VATRate) do
            if VATRate[i] >= 0 then begin
                NoOfLines := 2;
                VATProdPostingGroupCode :=
                  EInvoiceSalesHelper.NewVATPostingSetup(VATRate[i], ReminderHeader."VAT Bus. Posting Group", false);
                CreateReminderLines(ReminderHeader."No.", NoOfLines, VATProdPostingGroupCode, LineNo);
            end;

        exit(IssueReminder(ReminderHeader."No."));
    end;
}

