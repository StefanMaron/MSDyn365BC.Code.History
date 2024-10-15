#if not CLEAN17
report 11761 "Mass Uncertainty Payer Get"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Get All Uncertain Payers (Obsolete)';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.") WHERE(Blocked = FILTER(<> All));
            RequestFilterFields = "No.", "Vendor Posting Group", "Country/Region Code", "Tax Area Code";

            trigger OnAfterGetRecord()
            begin
                if IsUncertaintyPayerCheckPossible then begin
                    UncPayerMgt.AddVATRegNoToList("VAT Registration No.");
                    VendCount += 1;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if VendCount > 0 then
                    if ConfirmManagement.GetResponseOrDefault(StrSubstNo(UpdatedStatusQst, VendCount), true) then
                        UncPayerMgt.ImportUncPayerStatus(true);
            end;

            trigger OnPreDataItem()
            begin
                if UpdateOnlyUncertaintyPayers then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UpdateOnlyUncertaintyPayers; UpdateOnlyUncertaintyPayers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Only Uncertainty Payers';
                        ToolTip = 'Specifies if this batch job has to be only uncertainly payer actualized.';
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

    trigger OnPreReport()
    begin
        ElectronicallyGovernSetup.Get();
        ElectronicallyGovernSetup.TestField(UncertaintyPayerWebService);

        if UpdateOnlyUncertaintyPayers then
            UncPayerMgt.ImportUncPayerList(true);
    end;

    var
        ElectronicallyGovernSetup: Record "Electronically Govern. Setup";
        ConfirmManagement: Codeunit "Confirm Management";
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
        VendCount: Integer;
        UpdateOnlyUncertaintyPayers: Boolean;
        UpdatedStatusQst: Label 'Really actualize uncertainty status for %1 vendors?', Comment = '%1=COUNT';
}


#endif