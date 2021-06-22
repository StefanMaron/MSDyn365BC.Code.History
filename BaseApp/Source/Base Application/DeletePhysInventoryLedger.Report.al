report 789 "Delete Phys. Inventory Ledger"
{
    Caption = 'Delete Phys. Inventory Ledger';
    Permissions = TableData "Date Compr. Register" = rimd,
                  TableData "Phys. Inventory Ledger Entry" = rimd,
                  TableData "Inventory Period Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Phys. Inventory Ledger Entry"; "Phys. Inventory Ledger Entry")
        {
            RequestFilterFields = "Item No.", "Inventory Posting Group";

            trigger OnAfterGetRecord()
            var
                InvtPeriodEntry: Record "Inventory Period Entry";
                InvtPeriod: Record "Inventory Period";
            begin
                if not InvtPeriod.IsValidDate("Posting Date") then
                    InvtPeriod.ShowError("Posting Date");

                PhysInvtLedgEntry2 := "Phys. Inventory Ledger Entry";
                with PhysInvtLedgEntry2 do begin
                    SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");
                    CopyFilters("Phys. Inventory Ledger Entry");
                    SetRange("Item No.", "Item No.");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    SetRange("Inventory Posting Group", "Inventory Posting Group");
                    SetRange("Entry Type", "Entry Type");

                    Window.Update(1);
                    Window.Update(2);

                    Delete;

                    InvtPeriodEntry.RemoveItemRegNo("Entry No.", true);

                    NoOfDeleted := NoOfDeleted + 1;
                    Window.Update(3);
                end;

                if NoOfDeleted >= LastNoOfDeleted + 10 then begin
                    LastNoOfDeleted := NoOfDeleted;
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(Text000, false) then
                    CurrReport.Break();

                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007,
                  "Item No.",
                  "Posting Date",
                  NoOfDeleted);

                LastEntryNo := PhysInvtLedgEntry2.GetLastEntryNo();
                SetRange("Entry No.", 0, LastEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date of the period from which the program will suggest physical inventory ledger entries. The batch job will include all entries from this date to the ending date.';
                    }
                    field(EndingDate; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date of the period from which the program will suggest physical inventory ledger entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := Today;
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to delete the entries?';
        Text003: Label '%1 must be specified.';
        Text004: Label 'Deleting phys. inventory ledger entries...\\';
        Text005: Label 'Item No.             #1##########\';
        Text006: Label 'Date                 #2######\\';
        Text007: Label 'No. of entries del.  #3######';
        EntrdDateComprReg: Record "Date Compr. Register";
        PhysInvtLedgEntry2: Record "Phys. Inventory Ledger Entry";
        DateComprMgt: Codeunit DateComprMgt;
        Window: Dialog;
        LastEntryNo: Integer;
        NoOfDeleted: Integer;
        LastNoOfDeleted: Integer;
}

