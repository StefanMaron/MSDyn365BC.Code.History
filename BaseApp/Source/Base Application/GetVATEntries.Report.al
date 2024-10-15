report 31100 "Get VAT Entries"
{
    Caption = 'Get VAT Entries (Obsolete)';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("VAT Control Report Header"; "VAT Control Report Header")
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            begin
                TestField("No.");
                TestField("Start Date");
                TestField("End Date");
                TestField("VAT Statement Template Name");
                TestField("VAT Statement Name");

                if (StartDate < "Start Date") or (EndDate > "End Date") then
                    Error(DateMismashErr, "Start Date", "End Date");

                VATCtrlRptMgt.GetVATCtrlReportLines(
                  "VAT Control Report Header", StartDate, EndDate, VATStatementTemplate, VATStatementName, ProcessEntryType, true, UseMergeVATEntries);
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
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        Editable = false;
                        ToolTip = 'Specifies the starting date';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        Editable = false;
                        ToolTip = 'Specifies the last date in the period.';
                    }
                    field(VATStatementTemplate; VATStatementTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Template Name';
                        Editable = false;
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies vat statement template name';

                        trigger OnValidate()
                        begin
                            Clear(VATStatementName);
                        end;
                    }
                    field(VATStatementName; VATStatementName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Name';
                        Editable = false;
                        ToolTip = 'Specifies vat statement name';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            VATStmtManagement: Codeunit VATStmtManagement;
                        begin
                            exit(VATStmtManagement.LookupName(VATStatementTemplate, VATStatementName, Text));
                        end;
                    }
                    field(ProcessEntryType; ProcessEntryType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Control Report Lines';
                        OptionCaption = 'Add,Rewrite';
                        ToolTip = 'Specifies if vat control report lines will be added or rewritten';
                    }
                    field(UseMergeVATEntries; UseMergeVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Merge VAT Entries';
                        ToolTip = 'Specifies the option to optimize performance. Apply in the case of large number of VAT Entries.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        VATCtrlRptHdr: Record "VAT Control Report Header";
        VATCtrlRptMgt: Codeunit VATControlReportManagement;
        StartDate: Date;
        EndDate: Date;
        VATStatementTemplate: Code[10];
        VATStatementName: Code[10];
        ProcessEntryType: Option Add,Rewrite;
        DateMismashErr: Label 'Starting od Ending Date isn£ in allowed values range (%1..%2).', Comment = '%1="Start Date";%2="End Date"';
        UseMergeVATEntries: Boolean;

    [Scope('OnPrem')]
    procedure SetVATCtrlRepHeader(NewVATCtrlRptHdr: Record "VAT Control Report Header")
    begin
        VATCtrlRptHdr := NewVATCtrlRptHdr;
        InitializeRequest;
    end;

    local procedure InitializeRequest()
    begin
        StartDate := VATCtrlRptHdr."Start Date";
        EndDate := VATCtrlRptHdr."End Date";
        VATStatementTemplate := VATCtrlRptHdr."VAT Statement Template Name";
        VATStatementName := VATCtrlRptHdr."VAT Statement Name";

        ProcessEntryType := ProcessEntryType::Add;
    end;
}

