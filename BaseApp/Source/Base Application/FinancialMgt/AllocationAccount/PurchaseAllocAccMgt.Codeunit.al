namespace Microsoft.Finance.AllocationAccount.Purchase;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;

codeunit 2679 "Purchase Alloc. Acc. Mgt."
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
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        PurchaseLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        PurchaseLine.GetBySystemId(ParentSystemId);
        AmountToAllocate := PurchaseLine.Amount;
        PurchaseHeader.ReadIsolation := IsolationLevel::ReadUncommitted;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PostingDate := PurchaseHeader."Posting Date";

        if PurchaseLine."Alloc. Acc. Modified by User" then
            LoadManualAllocationLines(PurchaseLine, AllocationLine)
        else begin
            GetAllocationAccount(PurchaseLine, AllocationAccount);
            AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, PurchaseLine.Amount, PostingDate, PurchaseLine."Dimension Set ID", PurchaseLine."Currency Code");
            ReplaceInheritFromParent(AllocationLine, PurchaseLine);
        end;
    end;

    internal procedure LoadManualAllocationLines(var PurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
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

    local procedure ReplaceInheritFromParent(var AllocationLine: Record "Allocation Line"; var PurchaseLine: Record "Purchase Line")
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

        if PurchaseLine."No." = '' then
            Error(MustProvideAccountNoForInheritFromParentErr);

        AllocationLine.ModifyAll("Destination Account Number", PurchaseLine."No.");

        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"G/L Account");
            else
                Error(InvalidAccountTypeForInheritFromParentErr, PurchaseLine.Type);
        end;

        AllocationLine.Reset();
        AllocationLine.SetView(CurrentFilters);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure HandlePostDocument(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    var
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        AllocAccTelemetry.LogPurchaseInvoicePostingUsage();
        VerifyLinesFromDocument(PurchaseHeader);
        CreateLinesFromDocument(PurchaseHeader)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeShowDimensions', '', false, false)]
    local procedure HandleShowDimensions(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if (PurchaseLine."Type" <> PurchaseLine."Type"::"Allocation Account") then
            exit;

        if GuiAllowed() then
            if not Confirm(ChangeDimensionsOnAllocationDistributionsQst) then
                Error('');
    end;


    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckBeforeModifyLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        VerifyPurchaseLine(Rec);
        DeleteManualDistributionsIfLineChanged(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateNo', '', false, false)]
    local procedure HandleValidateLineNo(CurrentFieldNo: Integer; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if IsHandled then
            exit;

        if PurchaseLine."Type" <> PurchaseLine."Type"::"Allocation Account" then
            exit;

        IsHandled := true;

        VerifyPurchaseLine(PurchaseLine);
        if PurchaseLine.Description <> '' then
            exit;

        AllocationAccount.Get(PurchaseLine."No.");
        PurchaseLine.Description := AllocationAccount.Name;
    end;

    local procedure DeleteManualDistributionsIfLineChanged(var PurchaseLine: Record "Purchase Line")
    var
        PreviousPurchaseLine: Record "Purchase Line";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        DeleteAllocAccManualOverrideNeeded: Boolean;
    begin
        if PurchaseLine.IsTemporary() then
            exit;

        if (not AllocationAccountUsed(PurchaseLine)) then
            exit;

        PreviousPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not PreviousPurchaseLine.GetBySystemId(PurchaseLine.SystemId) then
            exit;

        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocAccManualOverride.IsEmpty() then
            exit;

        DeleteAllocAccManualOverrideNeeded := (PurchaseLine."Type" <> PreviousPurchaseLine."Type") or
                                              (PurchaseLine."No." <> PreviousPurchaseLine."No.") or
                                                 (PurchaseLine."Line Amount" <> PreviousPurchaseLine."Line Amount");

        if not DeleteAllocAccManualOverrideNeeded then
            exit;

        if GuiAllowed() then
            if not Confirm(DeleteManualOverridesQst) then
                Error('');

        AllocAccManualOverride.DeleteAll();
    end;

    local procedure AllocationAccountUsed(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit((PurchaseLine.Type = PurchaseLine.Type::"Allocation Account") or (PurchaseLine."Selected Alloc. Account No." <> ''));
    end;

    local procedure CreateLinesFromDocument(var PurchaseHeader: Record "Purchase Header")
    var
        AllocationPurchaseLine: Record "Purchase Line";
    begin
        AllocationPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationPurchaseLine.SetRange("Type", AllocationPurchaseLine."Type"::"Allocation Account");
        CreateLines(AllocationPurchaseLine);
        AllocationPurchaseLine.DeleteAll();

        AllocationPurchaseLine.Reset();
        AllocationPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationPurchaseLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        CreateLines(AllocationPurchaseLine);
        AllocationPurchaseLine.DeleteAll();
    end;

    local procedure CreateLines(var AllocationPurchaseLine: Record "Purchase Line")
    begin
        AllocationPurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if AllocationPurchaseLine.IsEmpty() then
            exit;

        AllocationPurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
        AllocationPurchaseLine.FindSet();
        repeat
            CreateLinesFromAllocationAccountLine(AllocationPurchaseLine);
        until AllocationPurchaseLine.Next() = 0;
    end;

    local procedure CreateLinesFromAllocationAccountLine(var AllocationAccountPurchaseLine: Record "Purchase Line")
    var
        ExistingAccountPurchaseLine: Record "Purchase Line";
        AllocationLine: Record "Allocation Line";
        AllocationAccount: Record "Allocation Account";
        NextLineNo: Integer;
        LastLineNo: Integer;
        Increment: Integer;
    begin
        if not GetAllocationAccount(AllocationAccountPurchaseLine, AllocationAccount) then
            Error(CannotGetAllocationAccountFromLineErr, AllocationAccountPurchaseLine."Line No.");

        VerifyAllocationAccount(AllocationAccount);

        GetOrGenerateAllocationLines(AllocationLine, AllocationAccountPurchaseLine.SystemId);
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        if AllocationLine.Count = 0 then
            Error(NoLinesGeneratedLbl, AllocationAccountPurchaseLine.RecordId);

        NextLineNo := GetNextLine(AllocationAccountPurchaseLine);
        LastLineNo := AllocationAccountPurchaseLine."Line No.";

        Increment := GetLineIncrement(AllocationAccountPurchaseLine."Line No.", NextLineNo, AllocationLine.Count);
        if Increment < -1 then begin
            Increment := 10000;
            LastLineNo := GetLastLine(AllocationAccountPurchaseLine)
        end;

        AllocationLine.Reset();
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        AllocationLine.FindSet();
        ExistingAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        ExistingAccountPurchaseLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        ExistingAccountPurchaseLine.GetBySystemId(AllocationAccountPurchaseLine.SystemId);

        repeat
            CreatePurchaseLine(ExistingAccountPurchaseLine, AllocationLine, LastLineNo, Increment);
        until AllocationLine.Next() = 0;

        DeleteManualOverrides(AllocationAccountPurchaseLine);
    end;

    local procedure DeleteManualOverrides(var PurchaseLine: Record "Purchase Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();
    end;

    local procedure VerifyLinesFromDocument(var PurchaseHeader: Record "Purchase Header")
    var
        AllocationAccountPurchaseLine: Record "Purchase Line";
    begin
        AllocationAccountPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationAccountPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationAccountPurchaseLine.SetRange("Type", AllocationAccountPurchaseLine."Type"::"Allocation Account");
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocationAccountPurchaseLine.FindSet() then
            exit;

        repeat
            VerifyPurchaseLines(AllocationAccountPurchaseLine);
        until AllocationAccountPurchaseLine.Next() = 0;

        AllocationAccountPurchaseLine.Reset();
        AllocationAccountPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationAccountPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationAccountPurchaseLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocationAccountPurchaseLine.FindSet() then
            exit;

        repeat
            VerifyPurchaseLines(AllocationAccountPurchaseLine);
        until AllocationAccountPurchaseLine.Next() = 0;
    end;

    local procedure CreatePurchaseLine(var AllocationPurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; var LastLineNo: Integer; Increment: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.TransferFields(AllocationPurchaseLine, true);
        PurchaseLine."Line No." := LastLineNo + Increment;
        PurchaseLine."Type" := PurchaseLine."Type"::"G/L Account";
        PurchaseLine.Validate("No.", AllocationLine."Destination Account Number");
        PurchaseLine.Quantity := AllocationPurchaseLine.Quantity;
        PurchaseLine."Unit Cost" := AllocationPurchaseLine."Unit Cost";
        PurchaseLine."Direct Unit Cost" := AllocationPurchaseLine."Direct Unit Cost";
        PurchaseLine.Validate("Line Amount", AllocationLine.Amount);

        TransferDimensionSetID(PurchaseLine, AllocationLine, AllocationPurchaseLine."Alloc. Acc. Modified by User");
        PurchaseLine."Allocation Account No." := AllocationLine."Allocation Account No.";
        PurchaseLine."Selected Alloc. Account No." := '';
        PurchaseLine.Insert(true);
        LastLineNo := PurchaseLine."Line No.";
    end;

    local procedure GetNextLine(var AllocationPurchaseLine: Record "Purchase Line"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", AllocationPurchaseLine."Document No.");
        PurchaseLine.SetRange("Document Type", AllocationPurchaseLine."Document Type");
        PurchaseLine.SetFilter("Line No.", '>%1', AllocationPurchaseLine."Line No.");
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if PurchaseLine.FindFirst() then
            exit(PurchaseLine."Line No.");

        exit(AllocationPurchaseLine."Line No." + 10000);
    end;

    local procedure GetLastLine(var AllocationPurchaseLine: Record "Purchase Line"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", AllocationPurchaseLine."Document No.");
        PurchaseLine.SetRange("Document Type", AllocationPurchaseLine."Document Type");
        PurchaseLine.SetFilter("Line No.", '>%1', AllocationPurchaseLine."Line No.");
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No.");

        exit(AllocationPurchaseLine."Line No.");
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

    local procedure GetAllocationAccount(var AllocationAccountPurchaseLine: Record "Purchase Line"; var AllocationAccount: Record "Allocation Account"): Boolean
    begin
        if AllocationAccountPurchaseLine."Selected Alloc. Account No." <> '' then
            exit(AllocationAccount.Get(AllocationAccountPurchaseLine."Selected Alloc. Account No."));

        if AllocationAccountPurchaseLine."Type" = AllocationAccountPurchaseLine."Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountPurchaseLine."No."));

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

    local procedure TransferDimensionSetID(var PurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; ModifiedByUser: Boolean)
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then
            exit;

        if PurchaseLine."Dimension Set ID" = AllocationLine."Dimension Set ID" then
            exit;

        if (PurchaseLine."Dimension Set ID" = 0) or ModifiedByUser then begin
            PurchaseLine."Dimension Set ID" := AllocationLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              PurchaseLine."Dimension Set ID", PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");

            exit;
        end;

        DimensionSetIDArr[1] := PurchaseLine."Dimension Set ID";
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        PurchaseLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifyPurchaseLines(var AllocationAccountPurchaseLine: Record "Purchase Line")
    begin
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationAccountPurchaseLine.FindSet() then
            exit;

        repeat
            VerifyPurchaseLine(AllocationAccountPurchaseLine);
        until AllocationAccountPurchaseLine.Next() = 0;
    end;

    internal procedure VerifySelectedAllocationAccountNo(var PurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if PurchaseLine."Selected Alloc. Account No." = '' then
            exit;

        if not (PurchaseLine.Type = PurchaseLine.Type::"G/L Account") then
            Error(InvalidAccountTypeForInheritFromParentErr, PurchaseLine.Type);

        AllocationAccount.Get(PurchaseLine."Selected Alloc. Account No.");
        VerifyAllocationAccount(AllocationAccount);
    end;

    local procedure VerifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        if not AllocationAccountUsed(PurchaseLine) then
            exit;

        if PurchaseLine."Selected Alloc. Account No." <> '' then
            VerifySelectedAllocationAccountNo(PurchaseLine)
        else begin
            if PurchaseLine."No." = '' then
                exit;

            AllocationAccount.Get(PurchaseLine."No.");
            VerifyAllocationAccount(AllocationAccount);
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(AllocationAccount."No.");
        end;
    end;

    var
        AllocationAccountMustOnlyDistributeToGLAccountsErr: Label 'The allocation account must contain G/L accounts as distribution accounts.';
        CannotGetAllocationAccountFromLineErr: Label 'Cannot get allocation account from Purchase line %1.', Comment = '%1 - Line No., it is an integer that identifies the line e.g. 10000, 200000.';
        NoLinesGeneratedLbl: Label 'No allocation account lines were generated for Purchase line %1.', Comment = '%1 - Unique identification of the line.';
        ChangeDimensionsOnAllocationDistributionsQst: Label 'The line is connected to the Allocation Account. Any dimensions that you change through this action will be merged with dimensions that are defined on the Allocation Line. To change the final dimensions you should invoke the Redistribute Account Allocations action.\\Do you want to continue?';
        DeleteManualOverridesQst: Label 'Modifying the line will delete all manual overrides for allocation account.\\Do you want to continue?';
        InvalidAccountTypeForInheritFromParentErr: Label 'Selected account type - %1 cannot be used for allocation accounts that have inherit from parent defined.', Comment = '%1 - Account type, e.g. G/L Account, Customer, Vendor, Bank Account, Fixed Asset, Item, Resource, Charge, Project, or Blank.';
        MustProvideAccountNoForInheritFromParentErr: Label 'You must provide an account number for allocation account with inherit from parent defined.';
}
