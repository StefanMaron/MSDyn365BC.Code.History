namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;

codeunit 212 "Res. Jnl.-Post Line"
{
    Permissions = TableData "Res. Ledger Entry" = rimd,
                  TableData "Resource Register" = rimd,
                  TableData "Time Sheet Line" = rm,
                  TableData "Time Sheet Detail" = rm;
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ResJournalLineGlobal: Record "Res. Journal Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        Resource: Record Resource;
        ResourceRegister: Record "Resource Register";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        ResJnlCheckLine: Codeunit "Res. Jnl.-Check Line";
        NextEntryNo: Integer;
        GLSetupRead: Boolean;

    procedure RunWithCheck(var ResJournalLine: Record "Res. Journal Line")
    begin
        ResJournalLineGlobal.Copy(ResJournalLine);
        Code();
        ResJournalLine := ResJournalLineGlobal;
    end;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResJnlLine(ResJournalLineGlobal, IsHandled);
        if not IsHandled then begin
            if ResJournalLineGlobal.EmptyLine() then
                exit;

            ResJnlCheckLine.RunCheck(ResJournalLineGlobal);
            OnCodeOnAfterRunCheck(ResJournalLineGlobal);

            if NextEntryNo = 0 then begin
                ResLedgerEntry.LockTable();
                NextEntryNo := ResLedgerEntry.GetLastEntryNo() + 1;
            end;

            if ResJournalLineGlobal."Document Date" = 0D then
                ResJournalLineGlobal."Document Date" := ResJournalLineGlobal."Posting Date";

            if ResourceRegister."No." = 0 then begin
                ResourceRegister.LockTable();
                if (not ResourceRegister.FindLast()) or (ResourceRegister."To Entry No." <> 0) then
                    InsertRegister(ResJournalLineGlobal);
            end;
            ResourceRegister."To Entry No." := NextEntryNo;
            OnBeforeResourceRegisterModify(ResJournalLineGlobal, ResourceRegister);
            ResourceRegister.Modify();

            Resource.Get(ResJournalLineGlobal."Resource No.");
            Resource.CheckResourcePrivacyBlocked(true);

            IsHandled := false;
            OnBeforeCheckResourceBlocked(Resource, IsHandled);
            if not IsHandled then
                Resource.TestField(Blocked, false);
            ResJournalLineGlobal."Resource Group No." := Resource."Resource Group No.";

            ResLedgerEntry.Init();
            ResLedgerEntry.CopyFromResJnlLine(ResJournalLineGlobal);

            GetGLSetup();
            ResLedgerEntry."Total Cost" := Round(ResLedgerEntry."Total Cost");
            ResLedgerEntry."Total Price" := Round(ResLedgerEntry."Total Price");
            if ResLedgerEntry."Entry Type" = ResLedgerEntry."Entry Type"::Sale then begin
                ResLedgerEntry.Quantity := -ResLedgerEntry.Quantity;
                ResLedgerEntry."Total Cost" := -ResLedgerEntry."Total Cost";
                ResLedgerEntry."Total Price" := -ResLedgerEntry."Total Price";
            end;
            ResLedgerEntry."Direct Unit Cost" := Round(ResLedgerEntry."Direct Unit Cost", GeneralLedgerSetup."Unit-Amount Rounding Precision");
            ResLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ResLedgerEntry."User ID"));
            ResLedgerEntry."Entry No." := NextEntryNo;
            ResourceUnitOfMeasure.Get(ResLedgerEntry."Resource No.", ResLedgerEntry."Unit of Measure Code");
            if ResourceUnitOfMeasure."Related to Base Unit of Meas." then
                ResLedgerEntry."Quantity (Base)" := ResLedgerEntry.Quantity * ResLedgerEntry."Qty. per Unit of Measure";

            if ResLedgerEntry."Entry Type" = ResLedgerEntry."Entry Type"::Usage then begin
                PostTimeSheetDetail(ResJournalLineGlobal, ResLedgerEntry."Quantity (Base)");
                ResLedgerEntry.Chargeable := IsChargable(ResJournalLineGlobal, ResLedgerEntry.Chargeable);
            end;

            OnBeforeResLedgEntryInsert(ResLedgerEntry, ResJournalLineGlobal);

            ResLedgerEntry.Insert(true);

            NextEntryNo := NextEntryNo + 1;
        end;

        OnAfterPostResJnlLine(ResJournalLineGlobal, ResLedgerEntry);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GeneralLedgerSetup.Get();
        GLSetupRead := true;
    end;

    local procedure PostTimeSheetDetail(ResJournalLine: Record "Res. Journal Line"; QtyToPost: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetManagement: Codeunit "Time Sheet Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostTimeSheetDetail(ResJournalLine, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        if ResJournalLine."Time Sheet No." <> '' then begin
            TimeSheetDetail.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.", ResJournalLine."Time Sheet Date");
            TimeSheetDetail."Posted Quantity" += QtyToPost;
            TimeSheetDetail.Posted := TimeSheetDetail.Quantity = TimeSheetDetail."Posted Quantity";
            TimeSheetDetail.Modify();
            TimeSheetLine.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.");
            TimeSheetManagement.CreateTSPostingEntry(TimeSheetDetail, ResJournalLine.Quantity, ResJournalLine."Posting Date", ResJournalLine."Document No.", TimeSheetLine.Description);

            TimeSheetDetail.SetRange("Time Sheet No.", ResJournalLine."Time Sheet No.");
            TimeSheetDetail.SetRange("Time Sheet Line No.", ResJournalLine."Time Sheet Line No.");
            TimeSheetDetail.SetRange(Posted, false);
            OnPostTimeSheetDetailOnAfterSetTimeSheetDetailFilters(TimeSheetDetail, ResJournalLine);
            if TimeSheetDetail.IsEmpty() then begin
                TimeSheetLine.Posted := true;
                TimeSheetLine.Modify();
            end;
        end;
    end;

    local procedure IsChargable(ResJournalLine: Record "Res. Journal Line"; Chargeable: Boolean): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if ResJournalLine."Time Sheet No." <> '' then begin
            TimeSheetLine.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.");
            exit(TimeSheetLine.Chargeable);
        end;
        exit(Chargeable);
    end;

    local procedure InsertRegister(var ResJournalLine: Record "Res. Journal Line")
    begin
        ResourceRegister.Init();
        ResourceRegister."No." := ResourceRegister."No." + 1;
        ResourceRegister."From Entry No." := NextEntryNo;
        ResourceRegister."To Entry No." := NextEntryNo;
        ResourceRegister."Creation Date" := Today();
        ResourceRegister."Creation Time" := Time();
        ResourceRegister."Source Code" := ResJournalLine."Source Code";
        ResourceRegister."Journal Batch Name" := ResJournalLine."Journal Batch Name";
        ResourceRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(ResourceRegister."User ID"));
        OnBeforeResourceRegisterInsert(ResJournalLine, ResourceRegister);
        ResourceRegister.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckResourceBlocked(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var ResLedgEntry: Record "Res. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLine(var ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostTimeSheetDetail(var ResJournalLine: Record "Res. Journal Line"; QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResLedgEntryInsert(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostTimeSheetDetailOnAfterSetTimeSheetDetailFilters(var TimeSheetDetail: Record "Time Sheet Detail"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceRegisterInsert(var ResJournalLine: Record "Res. Journal Line"; var ResourceRegister: Record "Resource Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceRegisterModify(var ResJournalLine: Record "Res. Journal Line"; var ResourceRegister: Record "Resource Register")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnAfterRunCheck(var ResJournalLine: Record "Res. Journal Line")
    begin
    end;
}

