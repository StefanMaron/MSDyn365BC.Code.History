// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;
using Microsoft.Sales.Document;
using System.Text;

codeunit 1033 "Job-Process Plan. Lines"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        FindMatchingPlanningLines();
        OnRunOnAfterSetFiltersOnJobPlanningLine(SalesHeader, Rec, TempJobPlanningLine);

        GetPlanningLines.SetRecords(TempJobPlanningLine);
        GetPlanningLines.SetTableView(TempJobPlanningLine);
        GetPlanningLines.SetSalesHeader(SalesHeader);
        GetPlanningLines.LookupMode := true;
        if GetPlanningLines.RunModal() <> ACTION::Cancel then;
    end;

    var
        SalesHeader: Record "Sales Header";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        GetPlanningLines: Page "Get Job Planning Lines";

    local procedure FindMatchingPlanningLines()
    var
        JobTask: Record "Job Task";
        JobPlanningLine2: Record "Job Planning Line";
        TaskBillingMethod: Enum "Task Billing Method";
        JobFilter, JobTaskFilter : Text;
    begin
        JobPlanningLine2.ReadIsolation(IsolationLevel::ReadUncommitted);
        JobPlanningLine2.SetFilter("Line Type", '%1|%2', JobPlanningLine2."Line Type"::Billable, JobPlanningLine2."Line Type"::"Both Budget and Billable");
        JobPlanningLine2.SetFilter("Qty. to Transfer to Invoice", '<>%1', 0);

        JobFilter := CreateJobFilter(TaskBillingMethod::"One customer");
        if JobFilter <> '' then begin
            JobPlanningLine2.SetFilter("Job No.", JobFilter);
            if JobPlanningLine2.FindSet() then
                repeat
                    TempJobPlanningLine := JobPlanningLine2;
                    TempJobPlanningLine.Insert();
                until JobPlanningLine2.Next() = 0;
        end;

        JobTaskFilter := CreateJobTaskFilter();
        if JobTaskFilter <> '' then begin
            JobPlanningLine2.SetFilter("Job No.", CreateJobFilter(TaskBillingMethod::"Multiple customers"));
            JobPlanningLine2.SetFilter("Job Task No.", JobTaskFilter);
            if JobPlanningLine2.FindSet() then
                repeat
                    if JobTask.Get(JobPlanningLine2."Job No.", JobPlanningLine2."Job Task No.")
                        and (JobTask."Sell-to Customer No." = SalesHeader."Sell-to Customer No.")
                            and (JobTask."Sell-to Customer No." = SalesHeader."Sell-to Customer No.") then begin
                        TempJobPlanningLine := JobPlanningLine2;
                        TempJobPlanningLine.Insert();
                    end;
                until JobPlanningLine2.Next() = 0;
        end;
    end;

    local procedure CreateJobFilter(TaskBillingMethod: Enum "Task Billing Method"): Text
    var
        Job: Record "Job";
    begin
        if TaskBillingMethod = TaskBillingMethod::"One customer" then begin
            Job.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
            Job.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        end;
        Job.SetRange("Task Billing Method", TaskBillingMethod);
        Job.SetRange("Invoice Currency Code", SalesHeader."Currency Code");
        exit(SelectionFilterManagement.GetSelectionFilterForJob(Job));
    end;

    local procedure CreateJobTaskFilter(): Text
    var
        Job: Record "Job";
        JobTask: Record "Job Task";
        JobFilter: Text;
    begin
        Job.SetRange("Task Billing Method", Job."Task Billing Method"::"Multiple customers");
        JobFilter := SelectionFilterManagement.GetSelectionFilterForJob(Job);

        JobTask.SetFilter("Job No.", JobFilter);
        JobTask.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        JobTask.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        JobTask.SetRange("Invoice Currency Code", SalesHeader."Currency Code");
        exit(SelectionFilterManagement.GetSelectionFilterForJobTask(JobTask));
    end;

    procedure SetSalesHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader.Get(SalesHeader2."Document Type", SalesHeader2."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
    end;

    procedure CreateInvLines(var JobPlanningLine2: Record "Job Planning Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine2.SetFilter("Qty. to Transfer to Invoice", '<>%1', 0);
        JobPlanningLine.Copy(JobPlanningLine2);
        JobPlanningLine.SetSkipCheckForMultipleJobsOnSalesLine(true);
        JobCreateInvoice.CreateSalesInvoiceLines(JobPlanningLine."Job No.", JobPlanningLine, SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Document Date", false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetFiltersOnJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var FilteredJobPlanningLine: Record "Job Planning Line")
    begin
    end;
}