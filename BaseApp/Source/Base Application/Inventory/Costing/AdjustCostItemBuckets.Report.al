namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

report 5804 "Adjust Cost - Item Buckets"
{
    ApplicationArea = Basic, Suite;
    ProcessingOnly = true;
    UseRequestPage = false;
    Permissions = TableData "Item Ledger Entry" = rimd,
                  TableData "Item Application Entry" = r,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rimd;
    Caption = 'Adjust Cost - Item Buckets';

    dataset
    {
        dataitem("CA Item Bucket"; "Cost Adj. Item Bucket")
        {
            DataItemTableView = sorting("Line No.");

            trigger OnPreDataItem()
            begin
                if IsEmpty() then
                    CurrReport.Quit();

                SetRange(Status, Status::Running);
                if not IsEmpty() then
                    Error(TaskIsRunningErr);

                SetRange(Status, Status::"Not started");
            end;

            trigger OnAfterGetRecord()
            begin
                Clear("Starting Date-Time");
                Clear("Ending Date-Time");
                Clear("Last Error");
                Clear("Last Error Call Stack");
                Clear("Failed Item No.");
                Modify();
            end;

            trigger OnPostDataItem()
            begin
                Commit();
                if TaskScheduler.CanCreateTask() then
                    TaskScheduler.CreateTask(Codeunit::"Cost Adj. Session Scheduler", 0, true, CompanyName(), CurrentDateTime())
                else
                    Codeunit.Run(Codeunit::"Cost Adj. Session Scheduler");
            end;
        }
    }

    var
        TaskIsRunningErr: Label 'The cost adjustment is now running. Please wait until it is finished.';
}