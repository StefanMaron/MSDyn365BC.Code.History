#if not CLEAN20
page 2822 "Native - Export Invoices"
{
    Caption = 'nativeInvoicingExportInvoices', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = true;
    ModifyAllowed = false;
    ODataKeyFields = "Code";
    PageType = List;
    SourceTable = "Native - Export Invoices";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(startDate; "Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'startDate', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Start Date" = 0D then
                            Error(StartDateErr);
                    end;
                }
                field(endDate; "End Date")
                {
                    ApplicationArea = All;
                    Caption = 'endDate', Locked = true;

                    trigger OnValidate()
                    begin
                        if "End Date" = 0D then
                            Error(EndDateErr);
                    end;
                }
                field(email; "E-mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        if "E-mail" = '' then
                            Error(EmailErr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        O365ExportInvoicesEmail: Codeunit "O365 Export Invoices + Email";
    begin
        if "Start Date" > "End Date" then
            Error(PeriodErr);
        O365ExportInvoicesEmail.ExportInvoicesToExcelandEmail("Start Date", "End Date", "E-mail");
        exit(true);
    end;

    var
        StartDateErr: Label 'The start date is not specified.';
        EndDateErr: Label 'The end date is not specified.';
        EmailErr: Label 'The email address is not specified.';
        PeriodErr: Label 'The specified period is not valid.';
}
#endif
