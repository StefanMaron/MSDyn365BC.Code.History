namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Telemetry;

page 242 "Consolidate Wizard"
{
    Caption = 'Run Consolidation';
    PageType = NavigatePage;
    SourceTable = "Business Unit";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            group(Step0)
            {
                Visible = (Step = 0);
                field(StartingDate; TempConsolidationProcess."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date for the consolidation period';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Starting Date" <> 0D) and (TempConsolidationProcess."Ending Date" <> 0D) then
                            ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", true);
                        SetNextActionEnabled();
                    end;
                }
                field(EndingDate; TempConsolidationProcess."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date for the consolidation period';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Starting Date" <> 0D) and (TempConsolidationProcess."Ending Date" <> 0D) then
                            ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", true);
                        SetNextActionEnabled();
                    end;
                }
                field(JournalTemplateName; TempConsolidationProcess."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal Template Name';
                    TableRelation = "Gen. Journal Template";
                    Tooltip = 'Specifies the name of the journal template that is used for posting.';
                    ShowMandatory = true;
                    Visible = JournalTemplateNameMandatory;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Journal Template Name" <> '') and (TempConsolidationProcess."Journal Batch Name" <> '') then
                            ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;

                }
                field(JournalBatchName; TempConsolidationProcess."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal Batch Name';
                    ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                    ShowMandatory = true;
                    Visible = JournalTemplateNameMandatory;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlManagement: Codeunit GenJnlManagement;
                    begin
                        if TempConsolidationProcess."Journal Template Name" = '' then
                            exit(false);
                        GenJournalLine."Journal Template Name" := TempConsolidationProcess."Journal Template Name";
                        GenJournalLine."Journal Batch Name" := TempConsolidationProcess."Journal Batch Name";
                        GenJnlManagement.SetJnlBatchName(GenJournalLine);
                        if GenJournalLine."Journal Batch Name" <> '' then
                            GenJournalBatch.Get(TempConsolidationProcess."Journal Template Name", GenJournalLine."Journal Batch Name");
                        Text := GenJournalLine."Journal Batch Name";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Journal Template Name" <> '') and (TempConsolidationProcess."Journal Batch Name" <> '') then
                            ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;
                }
                field(DocumentNo; TempConsolidationProcess."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Tooltip = 'Specifies the G/L document number used for posting.';
                    ShowMandatory = true;
                    Visible = not JournalTemplateNameMandatory;

                    trigger OnValidate()
                    begin
                        ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;
                }
                field(TransferedDimensions; TempConsolidationProcess."Dimensions to Transfer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Editable = false;
                    ToolTip = 'Specifies the dimensions to transfer from the imported entries';

                    trigger OnAssistEdit()
                    var
                        Dimension: Record Dimension;
                    begin
                        if Dimension.IsEmpty() then
                            Error(NoDimensionsInConsolidationCompanyErr);
                        DimensionSelectionBuffer.SetDimSelectionMultiple(3, REPORT::"Import Consolidation from DB", TempConsolidationProcess."Dimensions to Transfer");
                    end;
                }
                field(ParentCurrencyCode; TempConsolidationProcess."Parent Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parent Currency Code';
                    Tooltip = 'Specifies the parent currency code.';
                }
            }
            group(Step1)
            {
                Visible = (Step = 1);
                label(Description)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FullDescriptionTxt;
                }
                group(BusinessUnitsGroup)
                {
                    Caption = 'Business Units to consolidate';
                    ShowCaption = false;
                    Editable = true;
                    Enabled = true;
                    repeater(BusinessUnits)
                    {
                        field(Code; Rec.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Code';
                            ToolTip = 'Specifies the code of the business unit.';
                            Editable = false;
                            TableRelation = "Business Unit";
                            DrillDown = true;
                            StyleExpr = StyleTxt;
                        }
                        field(Name; CompanyName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Company Name';
                            ToolTip = 'Specifies the name of business unit.';
                            Editable = false;
                            StyleExpr = StyleTxt;
                        }
                        field(Consolidate; Rec.Consolidate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Consolidate';
                            ToolTip = 'Specifies if the business unit should be included in the consolidation.';

                            trigger OnValidate()
                            begin
                                UpdateCurrentRecAccessGrantedState();
                            end;
                        }
                        field(AccessGranted; AccessGranted)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Access Granted';
                            ToolTip = 'Specifies if access to the Business Central company of this business unit has been granted.';
                            OptionCaption = 'Not Needed,No,Yes';
                            Editable = false;
                        }
                        field("Default Data Import Method"; Rec."Default Data Import Method")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Data Import Method';
                            ToolTip = 'Specifies the default data import method for the business unit.';
                            StyleExpr = StyleTxt;
                        }
                    }
                }

            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Finalize)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Finish';
                Image = Approve;
                Visible = (Step = 1);

                trigger OnAction()
                begin
                    ConsolidateBusinessUnits.ValidateConsolidationParameters(TempConsolidationProcess, Rec, true);
                    ConsolidateBusinessUnits.StartConsolidation(TempConsolidationProcess, Rec);
                    Message(ConsolidationScheduledMsg);
                    CurrPage.Close();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Next';
                Image = NextRecord;
                Enabled = NextActionEnabled;
                Visible = (Step <> 1);

                trigger OnAction()
                begin
                    Step += 1;
                    SetNextActionEnabled();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Back';
                Image = PreviousRecord;
                Enabled = (Step <> 0);

                trigger OnAction()
                begin
                    Step -= 1;
                end;
            }
            action(GrantAccess)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Grant Access';
                InFooterBar = true;
                Visible = (Step = 1);
                Image = Lock;

                trigger OnAction()
                var
                    BusinessUnit: Record "Business Unit";
                    ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
                begin
                    CurrPage.SetSelectionFilter(BusinessUnit);
                    if BusinessUnit.Count() <> 1 then
                        Error(SelectOneBusinessUnitToProvideAccessErr);
                    BusinessUnit.FindFirst();
                    if BusinessUnit."Default Data Import Method" <> BusinessUnit."Default Data Import Method"::API then begin
                        Message(AccessIsAlreadyGrantedMsg);
                        exit;
                    end;
                    ImportConsolidationFromAPI.AcquireTokenAndStoreInIsolatedStorage(BusinessUnit);
                    UpdateCurrentRecAccessGrantedState(true);
                end;
            }
        }
    }
    var
        TempConsolidationProcess: Record "Consolidation Process" temporary;
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        ConsolidateBusinessUnits: Codeunit "Consolidate Business Units";
        AccessGrantedStates: Dictionary of [Code[20], Integer];
        CompanyName: Text;
        StyleTxt: Text;
        FullDescriptionTxt: Text;
        Step: Integer;
        AccessGranted: Option NotNeeded,No,Yes;
        JournalTemplateNameMandatory: Boolean;
        NextActionEnabled: Boolean;
        NoBusinessUnitsToConsolidateErr: Label 'There are no business units configured for consolidation. You can enable the field "Consolidate" in each of the business unit''s setup page.';
        ConsolidationScheduledMsg: Label 'The consolidation has been succesful. The current consolidation company has imported the entries from the selected business units. You can use reports like the "Consolidated Trial Balance" to view the consolidated entries';
        AccessIsAlreadyGrantedMsg: Label 'Access is already granted.';
        DescriptionTxt: Label 'Select the business units to consolidate with the column "Consolidate".';
        DescriptionMissingAuthTxt: Label 'The business units %1 have not been granted access. Select each of them and use the action "Grant Access" to authenticate into these companies.', Comment = '%1 - list of comma separated business units'' codes';
        NoDimensionsInConsolidationCompanyErr: Label 'There are no dimensions configured for the current consolidation company. You can add and configure dimensions in the "Dimensions" page.';
        SelectOneBusinessUnitToProvideAccessErr: Label 'Select only one business unit to provide access to.';
        NotPossibleToGetTokenMsg: Label 'It was not possible to get authorization for this business unit. You can verify the setup in the Business Unit Card page.';


    trigger OnOpenPage()
    var
        BusinessUnit: Record "Business Unit";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        FeatureTelemetry.LogUptake('0000KOK', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        GeneralLedgerSetup.Get();
        TempConsolidationProcess."Parent Currency Code" := GeneralLedgerSetup."LCY Code";
        JournalTemplateNameMandatory := GeneralLedgerSetup."Journal Templ. Name Mandatory";
        FullDescriptionTxt := DescriptionTxt;
        BusinessUnit.SetRange(Consolidate, true);
        if not BusinessUnit.FindSet() then
            Error(NoBusinessUnitsToConsolidateErr);
        repeat
            if BusinessUnitConfiguredForAutomaticImport(BusinessUnit) then begin
                Rec.TransferFields(BusinessUnit);
                AccessGrantedStates.Add(BusinessUnit.Code, AccessGranted::NotNeeded);
                Rec.Insert();
            end;
        until BusinessUnit.Next() = 0;
        SetNextActionEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateCurrentRecState();
    end;

    local procedure BusinessUnitConfiguredForAutomaticImport(BusinessUnit: Record "Business Unit"): Boolean
    begin
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit(BusinessUnit."Company Name" <> '');
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::API then
            exit(BusinessUnit."BC API URL" <> '');
    end;

    local procedure UpdateCurrentRecState()
    begin
        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::Database then
            CompanyName := Rec."Company Name";
        if Rec."Default Data Import Method" = Rec."Default Data Import Method"::API then
            CompanyName := Rec."External Company Name";
        UpdateCurrentRecAccessGrantedState();
    end;

    local procedure UpdateCurrentRecAccessGrantedState()
    begin
        UpdateCurrentRecAccessGrantedState(false);
    end;

    local procedure UpdateCurrentRecAccessGrantedState(WarnConfig: Boolean)
    begin
        AccessGranted := GetBusinessUnitAccessGranted(Rec, WarnConfig);
        StyleTxt := GetStyleExprForBusinessUnit(Rec, AccessGranted);
        AccessGrantedStates.Set(Rec.Code, AccessGranted);
        UpdateFullDescription();
    end;

    local procedure UpdateFullDescription(): Text
    var
        BusinessUnitCode: Code[20];
        BusinessUnitState: Option;
        CompaniesTxt: Text;
    begin
        FullDescriptionTxt := DescriptionTxt;
        foreach BusinessUnitCode in AccessGrantedStates.Keys() do begin
            BusinessUnitState := AccessGrantedStates.Get(BusinessUnitCode);
            if BusinessUnitState = AccessGranted::No then begin
                if CompaniesTxt <> '' then
                    CompaniesTxt += ', ';
                CompaniesTxt += BusinessUnitCode;
            end;
        end;
        if CompaniesTxt <> '' then
            FullDescriptionTxt += StrSubstNo(DescriptionMissingAuthTxt, CompaniesTxt);
    end;

    local procedure GetStyleExprForBusinessUnit(BusinessUnit: Record "Business Unit"; AccessGrantedStatus: Option): Text
    begin
        if not BusinessUnit.Consolidate then
            exit('None');
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit('Favorable');
        if AccessGrantedStatus = AccessGranted::No then
            exit('Attention');
        exit('Favorable');
    end;

    local procedure GetBusinessUnitAccessGranted(BusinessUnit: Record "Business Unit"; WarnConfig: Boolean): Option
    var
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit(AccessGranted::NotNeeded);
        if ImportConsolidationFromAPI.IsStoredTokenValidForBusinessUnit(BusinessUnit) then
            exit(AccessGranted::Yes);
        if WarnConfig then
            Message(NotPossibleToGetTokenMsg);
        exit(AccessGranted::No);
    end;

    local procedure SetNextActionEnabled()
    begin
        NextActionEnabled := ValidateDatesForConsolidation() and ValidateJournalForConsolidation();
    end;

    [TryFunction()]
    local procedure ValidateDatesForConsolidation()
    begin
        ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", false);
    end;

    [TryFunction()]
    local procedure ValidateJournalForConsolidation()
    begin
        ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
    end;
}