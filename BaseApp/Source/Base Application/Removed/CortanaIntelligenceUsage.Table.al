namespace System.AI;

using System.Environment;

table 2003 "Cortana Intelligence Usage"
{
    // // This table is used for Azure Machine Learning related features to control that amount of time used by all
    // // these features in total does not exceed the limit defined by Azure ML.The table is singleton and used only in SaaS.

    Caption = 'Cortana Intelligence Usage';
    ObsoleteState = Removed;
    ObsoleteReason = 'Renamed to Azure AI Usage';
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Service; Option)
        {
            Caption = 'Service';
            OptionCaption = 'Machine Learning,Computer Vision';
            OptionMembers = "Machine Learning","Computer Vision";
        }
        field(2; "Total Resource Usage"; Decimal)
        {
            Caption = 'Total Resource Usage';
            Editable = false;
            MinValue = 0;
        }
        field(3; "Original Resource Limit"; Decimal)
        {
            Caption = 'Original Resource Limit';
            Editable = false;
            MinValue = 0;
        }
        field(4; "Limit Period"; Option)
        {
            Caption = 'Limit Period';
            Editable = false;
            OptionCaption = 'Year,Month,Day,Hour';
            OptionMembers = Year,Month,Day,Hour;
        }
        field(5; "Last DateTime Updated"; DateTime)
        {
            Caption = 'Last DateTime Updated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Service)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ProcessingTimeLessThanZeroErr: Label 'The available Azure Machine Learning processing time is less than or equal to zero.';
        AzureMLCategoryTxt: Label 'AzureMLCategory', Locked = true;
        AzureMLLimitReachedTxt: Label 'The Azure ML usage limit has been reached', Locked = true;
        TestMode: Boolean;
        TestTime: Time;
        TestDate: Date;
        ImageAnalysisIsSetup: Boolean;

    procedure IncrementTotalProcessingTime(ServiceOption: Option; AzureMLServiceProcessingTime: Decimal)
    begin
        if AzureMLServiceProcessingTime <= 0 then
            Error(ProcessingTimeLessThanZeroErr);

        if GetSingleInstance(ServiceOption) then begin
            "Total Resource Usage" += AzureMLServiceProcessingTime;
            "Last DateTime Updated" := GetCurrentDateTime();
            Modify(true);
        end;
    end;

    procedure IsAzureMLLimitReached(ServiceOption: Option; AzureMLUsageLimit: Decimal): Boolean
    begin
        if GetSingleInstance(ServiceOption) then
            if GetTotalProcessingTime(ServiceOption) >= AzureMLUsageLimit then begin
                Session.LogMessage('00001T1', AzureMLLimitReachedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureMLCategoryTxt);
                exit(true);
            end;
        exit(false);
    end;

    procedure GetTotalProcessingTime(ServiceOption: Option): Decimal
    begin
        // in case Azure ML is used by other features processing time should be added here
        if GetSingleInstance(ServiceOption) then
            exit("Total Resource Usage");
    end;

    [NonDebuggable]
    procedure GetSingleInstance(ServiceOption: Option): Boolean
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        MLPredictionManagement: Codeunit "ML Prediction Management";
        EnvironmentInfo: Codeunit "Environment Information";
        ApiUri: Text[250];
        ApiKey: SecretText;
        LimitType: Option;
        LimitValue: Decimal;
        LimitValueInt: Integer;
        CallModify: Boolean;
        ResetTotalProcessingTime: Boolean;
    begin
        if (ServiceOption = Service::"Machine Learning") and (not EnvironmentInfo.IsSaaS()) then
            exit(false);

        SetRange(Service, ServiceOption);
        if not FindFirst() then begin
            Init();
            Service := ServiceOption;
            "Last DateTime Updated" := GetCurrentDateTime();
            Insert();
        end;

        case ServiceOption of
            Service::"Computer Vision":
                begin
                    if "Original Resource Limit" = 0 then begin
                        "Original Resource Limit" := 999;
                        "Limit Period" := "Limit Period"::Year;
                    end;

                    if not ImageAnalysisSetup.Get() then begin
                        ImageAnalysisSetup.Init();
                        ImageAnalysisSetup.Insert();
                    end;

                    if (not ImageAnalysisIsSetup) and
                       ImageAnalysisSetup.GetApiKeyAsSecret().IsEmpty() and (ImageAnalysisSetup."Api Uri" = '') and
                       EnvironmentInfo.IsSaaS()
                    then
                        if ImageAnalysisManagement.GetImageAnalysisCredentials(ApiKey, ApiUri, LimitType, LimitValueInt) then begin
                            "Original Resource Limit" := LimitValueInt;
                            "Limit Period" := LimitType;
                            CallModify := true;
                        end;
                end;
            Service::"Machine Learning":
                if MLPredictionManagement.GetMachineLearningCredentials(ApiUri, ApiKey, LimitType, LimitValue) then begin
                    "Original Resource Limit" := LimitValue;
                    "Limit Period" := LimitType;
                    CallModify := true;
                end;
        end;

        case "Limit Period" of
            "Limit Period"::Year:
                ResetTotalProcessingTime := HasChangedYear("Last DateTime Updated");
            "Limit Period"::Month:
                ResetTotalProcessingTime := HasChangedMonth("Last DateTime Updated");
            "Limit Period"::Day:
                ResetTotalProcessingTime := HasChangedDay("Last DateTime Updated");
            "Limit Period"::Hour:
                ResetTotalProcessingTime := HasChangedHour("Last DateTime Updated");
        end;
        if ResetTotalProcessingTime then begin
            "Total Resource Usage" := 0;
            CallModify := true;
        end;

        if CallModify then
            Modify();
        exit(true);
    end;

    procedure SetTestMode(InputTestDate: Date; InputTestTime: Time)
    begin
        TestMode := true;
        TestDate := InputTestDate;
        TestTime := InputTestTime;
    end;

    local procedure GetCurrentDateTime(): DateTime
    begin
        if TestMode then
            exit(CreateDateTime(TestDate, TestTime));

        exit(CurrentDateTime);
    end;

    local procedure GetCurentDate(): Date
    begin
        exit(DT2Date(GetCurrentDateTime()));
    end;

    procedure HasChangedYear(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 3));
    end;

    procedure HasChangedMonth(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 2) or HasChangedYear(PreviousDateTime));
    end;

    procedure HasChangedDay(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 1) or HasChangedMonth(PreviousDateTime));
    end;

    local procedure HasChangedPeriod(PreviousDateTime: DateTime; What: Integer): Boolean
    begin
        exit(Date2DMY(GetCurentDate(), What) <> Date2DMY(DT2Date(PreviousDateTime), What));
    end;

    procedure HasChangedHour(PreviousDateTime: DateTime): Boolean
    var
        PreviousRounded: DateTime;
        CurrentRounded: DateTime;
    begin
        PreviousRounded := RoundDateTime(PreviousDateTime, 1000 * 3600, '<');
        CurrentRounded := RoundDateTime(GetCurrentDateTime(), 1000 * 3600, '<');
        exit(CurrentRounded <> PreviousRounded);
    end;

    procedure SetImageAnalysisIsSetup(NewValue: Boolean)
    begin
        ImageAnalysisIsSetup := NewValue;
    end;
}

