namespace Microsoft.Finance.AllocationAccount.Sales;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;

codeunit 2678 "Sales Alloc. Acc. Mgt."
{
    internal procedure GetOrGenerateAllocationLines(var AllocationLine: Record "Allocation Line"; var ParentSystemId: Guid)
    var
        AmountToAllocate: Decimal;
        PostingDate: Date;
    begin
        GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, AmountToAllocate, PostingDate);
    end;

    internal procedure GetOrGenerateAllocationLines(var AllocationLine: Record "Allocation Line"; var ParentSystemId: Guid; var AmountToAllocate: Decimal; var PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        SalesLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        SalesLine.GetBySystemId(ParentSystemId);
        AmountToAllocate := SalesLine.Amount;
        PostingDate := SalesLine."Posting Date";

        if SalesLine."Alloc. Acc. Modified by User" then
            LoadManualAllocationLines(SalesLine, AllocationLine)
        else begin
            SalesHeader.ReadIsolation := IsolationLevel::ReadUncommitted;
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            GetAllocationAccount(SalesLine, AllocationAccount);
            AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, SalesLine.Amount, SalesHeader."Posting Date", SalesLine."Dimension Set ID", SalesLine."Currency Code");
            ReplaceInheritFromParent(AllocationLine, SalesLine);
        end;
    end;

    internal procedure LoadManualAllocationLines(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.FindSet() then
            exit;

        repeat
            AllocationLine."Line No." := AllocAccManualOverride."Line No.";
            AllocationLine."Destination Account Type" := AllocAccManualOverride."Destination Account Type";
            AllocationLine."Destination Account Number" := AllocAccManualOverride."Destination Account Number";
            AllocationLine."Global Dimension 1 Code" := AllocAccManualOverride."Global Dimension 1 Code";
            AllocationLine."Global Dimension 2 Code" := AllocAccManualOverride."Global Dimension 2 Code";
            AllocationLine."Allocation Account No." := AllocAccManualOverride."Allocation Account No.";
            AllocationLine."Dimension Set ID" := AllocAccManualOverride."Dimension Set ID";
            AllocationLine.Amount := AllocAccManualOverride.Amount;
            AllocationLine.Insert();
        until AllocAccManualOverride.Next() = 0;
    end;

    local procedure ReplaceInheritFromParent(var AllocationLine: Record "Allocation Line"; var SalesLine: Record "Sales Line")
    var
        CurrentFilters: Text;
    begin
        CurrentFilters := AllocationLine.GetView();
        AllocationLine.Reset();
        AllocationLine.SetRange(AllocationLine."Destination Account Type", AllocationLine."Destination Account Type"::"Inherit from Parent");
        if AllocationLine.IsEmpty then begin
            AllocationLine.Reset();
            AllocationLine.SetView(CurrentFilters);
            exit;
        end;

        if SalesLine."No." = '' then
            Error(MustProvideAccountNoForInheritFromParentErr);

        AllocationLine.ModifyAll("Destination Account Number", SalesLine."No.");

        case SalesLine.Type of
            SalesLine.Type::"G/L Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"G/L Account");
            else
                Error(InvalidAccountTypeForInheritFromParentErr, SalesLine.Type);
        end;

        AllocationLine.Reset();
        AllocationLine.SetView(CurrentFilters);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure HandlePostDocument(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean; var IsHandled: Boolean)
    var
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        AllocAccTelemetry.LogSalesInvoicePostingUsage();
        VerifyLinesFromDocument(SalesHeader);
        CreateLinesFromDocument(SalesHeader)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeShowDimensions', '', false, false)]
    local procedure HandleShowDimensions(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsChanged: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if (SalesLine."Type" <> SalesLine."Type"::"Allocation Account") then
            exit;

        if GuiAllowed() then
            if not Confirm(ChangeDimensionsOnAllocationDistributionsQst) then
                Error('');
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckBeforeModifyLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        VerifySalesLine(Rec);
        DeleteManualDistributionsIfLineChanged(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateNo', '', false, false)]
    local procedure HandleValidateLineNo(CurrentFieldNo: Integer; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if IsHandled then
            exit;

        if SalesLine."Type" <> SalesLine."Type"::"Allocation Account" then
            exit;

        IsHandled := true;

        VerifySalesLine(SalesLine);
        if SalesLine.Description <> '' then
            exit;

        AllocationAccount.Get(SalesLine."No.");
        SalesLine.Description := AllocationAccount.Name;
    end;

    local procedure DeleteManualDistributionsIfLineChanged(var SalesLine: Record "Sales Line")
    var
        PreviousSalesLine: Record "Sales Line";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        DeleteAllocAccManualOverrideNeeded: Boolean;
    begin
        if SalesLine.IsTemporary() then
            exit;

        if (not AllocationAccountUsed(SalesLine)) then
            exit;

        PreviousSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not PreviousSalesLine.GetBySystemId(SalesLine.SystemId) then
            exit;

        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocAccManualOverride.IsEmpty() then
            exit;

        DeleteAllocAccManualOverrideNeeded := (SalesLine."Type" <> PreviousSalesLine."Type") or
                                              (SalesLine."No." <> PreviousSalesLine."No.") or
                                                 (SalesLine."Line Amount" <> PreviousSalesLine."Line Amount");

        if not DeleteAllocAccManualOverrideNeeded then
            exit;

        if GuiAllowed() then
            if not Confirm(DeleteManualOverridesQst) then
                Error('');

        AllocAccManualOverride.DeleteAll();
    end;

    local procedure AllocationAccountUsed(var SalesLine: Record "Sales Line"): Boolean
    begin
        exit((SalesLine.Type = SalesLine.Type::"Allocation Account") or (SalesLine."Selected Alloc. Account No." <> ''));
    end;

    local procedure CreateLinesFromDocument(var SalesHeader: Record "Sales Header")
    var
        AllocationSalesLine: Record "Sales Line";
    begin
        AllocationSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationSalesLine.SetRange("Type", AllocationSalesLine."Type"::"Allocation Account");
        CreateLines(AllocationSalesLine);
        AllocationSalesLine.DeleteAll();

        AllocationSalesLine.Reset();
        AllocationSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationSalesLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        CreateLines(AllocationSalesLine);
        AllocationSalesLine.DeleteAll();
    end;

    local procedure CreateLines(var AllocationSalesLine: Record "Sales Line")
    begin
        AllocationSalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if AllocationSalesLine.IsEmpty() then
            exit;

        AllocationSalesLine.ReadIsolation := IsolationLevel::UpdLock;
        AllocationSalesLine.FindSet();
        repeat
            CreateLinesFromAllocationAccountLine(AllocationSalesLine);
        until AllocationSalesLine.Next() = 0;
    end;

    local procedure CreateLinesFromAllocationAccountLine(var AllocationAccountSalesLine: Record "Sales Line")
    var
        ExistingAccountSalesLine: Record "Sales Line";
        AllocationLine: Record "Allocation Line";
        AllocationAccount: Record "Allocation Account";
        NextLineNo: Integer;
        LastLineNo: Integer;
        Increment: Integer;
    begin
        if not GetAllocationAccount(AllocationAccountSalesLine, AllocationAccount) then
            Error(CannotGetAllocationAccountFromLineErr, AllocationAccountSalesLine."Line No.");

        VerifyAllocationAccount(AllocationAccount);

        GetOrGenerateAllocationLines(AllocationLine, AllocationAccountSalesLine.SystemId);
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        if AllocationLine.Count = 0 then
            Error(NoLinesGeneratedLbl, AllocationAccountSalesLine.RecordId);

        NextLineNo := GetNextLine(AllocationAccountSalesLine);
        LastLineNo := AllocationAccountSalesLine."Line No.";

        Increment := GetLineIncrement(AllocationAccountSalesLine."Line No.", NextLineNo, AllocationLine.Count);
        if Increment < -1 then begin
            Increment := 10000;
            LastLineNo := GetLastLine(AllocationAccountSalesLine)
        end;

        AllocationLine.Reset();
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        AllocationLine.FindSet();
        ExistingAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        ExistingAccountSalesLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        ExistingAccountSalesLine.GetBySystemId(AllocationAccountSalesLine.SystemId);

        repeat
            CreateSalesLine(ExistingAccountSalesLine, AllocationLine, LastLineNo, Increment);
        until AllocationLine.Next() = 0;

        DeleteManualOverrides(AllocationAccountSalesLine);
    end;

    local procedure DeleteManualOverrides(var SalesLine: Record "Sales Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();
    end;

    local procedure VerifyLinesFromDocument(var SalesHeader: Record "Sales Header")
    var
        AllocationAccountSalesLine: Record "Sales Line";
    begin
        AllocationAccountSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationAccountSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationAccountSalesLine.SetRange("Type", AllocationAccountSalesLine."Type"::"Allocation Account");
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocationAccountSalesLine.FindSet() then
            exit;

        repeat
            VerifySalesLines(AllocationAccountSalesLine);
        until AllocationAccountSalesLine.Next() = 0;

        AllocationAccountSalesLine.Reset();
        AllocationAccountSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationAccountSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationAccountSalesLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocationAccountSalesLine.FindSet() then
            exit;

        repeat
            VerifySalesLines(AllocationAccountSalesLine);
        until AllocationAccountSalesLine.Next() = 0;
    end;

    local procedure CreateSalesLine(var AllocationSalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; var LastLineNo: Integer; Increment: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.TransferFields(AllocationSalesLine, true);
        SalesLine."Line No." := LastLineNo + Increment;
        SalesLine."Type" := SalesLine."Type"::"G/L Account";
        SalesLine.Validate("No.", AllocationLine."Destination Account Number");
        SalesLine.Quantity := AllocationSalesLine.Quantity;
        SalesLine."Unit Price" := AllocationSalesLine."Unit Price";
        SalesLine.Validate("Line Amount", AllocationLine.Amount);

        TransferDimensionSetID(SalesLine, AllocationLine, AllocationSalesLine."Alloc. Acc. Modified by User");
        SalesLine."Allocation Account No." := AllocationLine."Allocation Account No.";
        SalesLine."Selected Alloc. Account No." := '';
        OnBeforeCreateSalesLine(SalesLine, AllocationLine);
        SalesLine.Insert(true);
        LastLineNo := SalesLine."Line No.";
    end;

    local procedure GetNextLine(var AllocationSalesLine: Record "Sales Line"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", AllocationSalesLine."Document No.");
        SalesLine.SetRange("Document Type", AllocationSalesLine."Document Type");
        SalesLine.SetFilter("Line No.", '>%1', AllocationSalesLine."Line No.");
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if SalesLine.FindFirst() then
            exit(SalesLine."Line No.");

        exit(AllocationSalesLine."Line No." + 10000);
    end;

    local procedure GetLastLine(var AllocationSalesLine: Record "Sales Line"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", AllocationSalesLine."Document No.");
        SalesLine.SetRange("Document Type", AllocationSalesLine."Document Type");
        SalesLine.SetFilter("Line No.", '>%1', AllocationSalesLine."Line No.");
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if SalesLine.FindLast() then
            exit(SalesLine."Line No.");

        exit(AllocationSalesLine."Line No.");
    end;


    local procedure GetLineIncrement(CurrentLineNo: Integer; NextLineNo: Integer; LinesToInsert: Integer): Integer
    var
        Increment: Integer;
    begin
        Increment := Round((NextLineNo - CurrentLineNo) / LinesToInsert, 1);
        if Increment < LinesToInsert then
            exit(-1);

        if Increment >= 1000 then
            exit(1000);

        if Increment >= 100 then
            exit(100);

        if Increment >= 10 then
            exit(10);

        exit(Increment);
    end;

    local procedure GetAllocationAccount(var AllocationAccountSalesLine: Record "Sales Line"; var AllocationAccount: Record "Allocation Account"): Boolean
    begin
        if AllocationAccountSalesLine."Selected Alloc. Account No." <> '' then
            exit(AllocationAccount.Get(AllocationAccountSalesLine."Selected Alloc. Account No."));

        if AllocationAccountSalesLine."Type" = AllocationAccountSalesLine."Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountSalesLine."No."));

        exit(false);
    end;

    internal procedure VerifyAllocationAccount(var AllocationAccount: Record "Allocation Account")
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        AllocAccountDistribution.SetFilter("Destination Account Type", '<>%1&<>%2', AllocAccountDistribution."Destination Account Type"::"G/L Account", AllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
        if not AllocAccountDistribution.IsEmpty() then
            Error(AllocationAccountMustOnlyDistributeToGLAccountsErr);
    end;

    local procedure TransferDimensionSetID(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; ModifiedByUser: Boolean)
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then
            exit;

        if SalesLine."Dimension Set ID" = AllocationLine."Dimension Set ID" then
            exit;

        if (SalesLine."Dimension Set ID" = 0) or ModifiedByUser then begin
            SalesLine."Dimension Set ID" := AllocationLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");

            exit;
        end;

        DimensionSetIDArr[1] := SalesLine."Dimension Set ID";
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        SalesLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifySalesLines(var AllocationAccountSalesLine: Record "Sales Line")
    begin
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationAccountSalesLine.FindSet() then
            exit;

        repeat
            VerifySalesLine(AllocationAccountSalesLine);
        until AllocationAccountSalesLine.Next() = 0;
    end;

    internal procedure VerifySelectedAllocationAccountNo(var SalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if SalesLine."Selected Alloc. Account No." = '' then
            exit;

        if not (SalesLine.Type = SalesLine.Type::"G/L Account") then
            Error(InvalidAccountTypeForInheritFromParentErr, SalesLine.Type);

        AllocationAccount.Get(SalesLine."Selected Alloc. Account No.");
        VerifyAllocationAccount(AllocationAccount);
    end;

    local procedure VerifySalesLine(var SalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        if not AllocationAccountUsed(SalesLine) then
            exit;

        OnBeforeVerifySalesLine(SalesLine);
        if SalesLine."Selected Alloc. Account No." <> '' then
            VerifySelectedAllocationAccountNo(SalesLine)
        else begin
            if SalesLine."No." = '' then
                exit;

            AllocationAccount.Get(SalesLine."No.");
            VerifyAllocationAccount(AllocationAccount);
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(AllocationAccount."No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLine(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifySalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    var
        AllocationAccountMustOnlyDistributeToGLAccountsErr: Label 'The allocation account must contain G/L accounts as distribution accounts.';
        CannotGetAllocationAccountFromLineErr: Label 'Cannot get allocation account from sales line %1.', Comment = '%1 - Line No., it is an integer that identifies the line e.g. 10000, 200000.';
        NoLinesGeneratedLbl: Label 'No allocation account lines were generated for sales line %1.', Comment = '%1 - Unique identification of the line.';
        ChangeDimensionsOnAllocationDistributionsQst: Label 'The line is connected to the Allocation Account. Any dimensions that you change through this action will be merged with dimensions that are defined on the Allocation Line. To change the final dimensions you should invoke the Redistribute Account Allocations action.\\Do you want to continue?';
        DeleteManualOverridesQst: Label 'Modifying the line will delete all manual overrides for allocation account.\\Do you want to continue?';
        InvalidAccountTypeForInheritFromParentErr: Label 'Selected account type - %1 cannot be used for allocation accounts that have inherit from parent defined.', Comment = '%1 - Account type, e.g. G/L Account, Customer, Vendor, Bank Account, Fixed Asset, Item, Resource, Charge, Project, or Blank.';
        MustProvideAccountNoForInheritFromParentErr: Label 'You must provide an account number for allocation account with inherit from parent defined.';
}
