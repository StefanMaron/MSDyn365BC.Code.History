codeunit 144048 AdditionalPostingDateChecks
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesBefore()
    begin
        ResetSetups;

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', 0D),
          'Expected a posting date less than the Gen. Journal Template Allow Posting From to return true in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesAfter()
    begin
        ResetSetups;

        // Verify posting date after allow from to
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', 0D),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting To to return true in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesInside()
    begin
        ResetSetups;

        // Verify posting date inside allow to an from
        Assert.IsFalse(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-1D>', '<1D>', 0D),
          'Expected a posting date inside than the Gen. Journal Template Allow Posting From and To return false in DateNotAllowed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeUserSetupBefore()
    var
        PostingDate: Date;
    begin
        ResetSetups;

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate);

        // Configure User setup so the posting date is valid
        ReconfigureUserSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting From return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeUserSetupAfter()
    var
        PostingDate: Date;
    begin
        ResetSetups;

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate);

        // Configure User setup so the posting date is valid
        ReconfigureUserSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting From return true in DateNotAllowed even is UserSetup allows it');

        // Verify posting date after allow to date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', PostingDate),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting To return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeGLSetupBefore()
    var
        PostingDate: Date;
    begin
        ResetSetups;

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate);

        // Configure General Ledger setup so the posting date is valid
        ReconfigureGLSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting From return true in DateNotAllowed even is UserSetup allows it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGenJournalTemplateAllowPostingDatesComesBeforeGLSetupAfter()
    var
        PostingDate: Date;
    begin
        ResetSetups;

        PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate);

        // Configure General Ledger setup so the posting date is valid
        ReconfigureGLSetup(CalcDate('<-1D>', PostingDate), CalcDate('<1D>', PostingDate));

        // Verify posting date before allow from date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<1D>', '<2D>', PostingDate),
          'Expected a posting date less than the Gen. Journal Template Allow Posting From return true in DateNotAllowed even is UserSetup allows it');

        // Verify posting date after allow to date
        Assert.IsTrue(
          RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates('<-2D>', '<-1D>', PostingDate),
          'Expected a posting date greater than the Gen. Journal Template Allow Posting To return true in DateNotAllowed even is UserSetup allows it');
    end;

    local procedure ResetSetups()
    begin
        ResetGLSetup;
        ResetUserSetup;
    end;

    local procedure ResetGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            Clear("Allow Posting From");
            Clear("Allow Posting To");
            Modify;
        end;
    end;

    local procedure ResetUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        with UserSetup do
            if Get(UserId) then begin
                Clear("Allow Posting From");
                Clear("Allow Posting To");
                Modify;
            end;
    end;

    local procedure ReconfigureGenJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; AllowPostingFrom: Date; AllowPostingTo: Date)
    begin
        with GenJournalTemplate do begin
            "Allow Posting From" := AllowPostingFrom;
            "Allow Posting To" := AllowPostingTo;
            Modify;
        end;
    end;

    local procedure ReconfigureUserSetup(AllowPostingFrom: Date; AllowPostingTo: Date)
    var
        UserSetup: Record "User Setup";
    begin
        with UserSetup do begin
            if not Get(UserId) then begin
                "User ID" := UserId;
                Insert;
            end;

            "Allow Posting From" := AllowPostingFrom;
            "Allow Posting To" := AllowPostingTo;
            Modify;
        end;
    end;

    local procedure ReconfigureGLSetup(AllowPostingFrom: Date; AllowPostingTo: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            "Allow Posting From" := AllowPostingFrom;
            "Allow Posting To" := AllowPostingTo;
            Modify;
        end;
    end;

    local procedure RunDateNotAllowedForGenJournalTemplateWithAllowPostingDates(AllowPostingFromDateExpression: Text; AllowPostingToDateExpression: Text; PostingDate: Date): Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        AllowFrom: DateFormula;
        AllowTo: DateFormula;
    begin
        if PostingDate = 0D then
            PostingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(1000)), WorkDate);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        Evaluate(AllowFrom, AllowPostingFromDateExpression);
        Evaluate(AllowTo, AllowPostingToDateExpression);

        ReconfigureGenJournalTemplate(GenJournalTemplate,
          CalcDate(AllowFrom, PostingDate),
          CalcDate(AllowTo, PostingDate));

        exit(GenJnlCheckLine.DateNotAllowed(PostingDate, GenJournalTemplate.Name));
    end;
}

