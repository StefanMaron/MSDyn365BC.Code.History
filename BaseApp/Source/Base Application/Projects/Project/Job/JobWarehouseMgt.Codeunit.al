// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Projects.Project.Planning;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;

codeunit 5998 "Job Warehouse Mgt."
{
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        if SourceType = Database::"Job Planning Line" then
            ShowJobPlanningLine(SourceLineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        Job: Record Job;
    begin
        if SourceType = Database::Job then
            if Job.Get(SourceNo) then
                Page.RunModal(Page::"Job Card", Job);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowWhseActivityDocLine', '', false, false)]
    local procedure OnAfterShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        if WhseActivityDocType = WhseActivityDocType::Job then
            ShowJobPlanningLine(WhseDocLineNo);
    end;

    local procedure ShowJobPlanningLine(WhseDocLineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job Contract Entry No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Job Planning Lines", JobPlanningLine);
    end;

    procedure JobPlanningLineVerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; FieldNo: Integer)
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
        then
            if not WhseValidateSourceLine.WhseWorkSheetLinesExist(
                Database::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
            then
                exit;

        NewRecordRef.GetTable(NewJobPlanningLine);
        OldRecordRef.GetTable(OldJobPlanningLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo);
    end;

    procedure JobPlanningLineDelete(var JobPlanningLine: Record "Job Planning Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(DATABASE::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(JobPlanningLine.TableCaption());

        if WhseValidateSourceLine.WhseWorkSheetLinesExist(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(JobPlanningLine.TableCaption());
    end;
}
