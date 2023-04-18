table 2004 "Azure AI Usage"
{
    // // This table is used for Azure Machine Learning related features to control that amount of time used by all
    // // these features in total does not exceed the limit defined by Azure ML.The table is singleton and used only in SaaS.

    ObsoleteState = Pending;
    ObsoleteReason = 'Table will be marked as internal. Use codeunit ''Azure AI Usage'' to read the data from the table.';
    ObsoleteTag = '17.0';
    ReplicateData = false;
    Caption = 'Azure AI Usage';
    Permissions = TableData "Azure AI Usage" = rimd;

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
        AzureAIUsage: Codeunit "Azure AI Usage Impl.";


    [Obsolete('Reference IncrementTotalProcessingTime function from codeunit Azure AI Usage instead', '17.0')]
    procedure IncrementTotalProcessingTime(ServiceOption: Option; AzureMLServiceProcessingTime: Decimal)
    begin
        AzureAIUsage.IncrementTotalProcessingTime("Azure AI Service".FromInteger(ServiceOption), AzureMLServiceProcessingTime, Rec);
    end;

    [Obsolete('Reference IsLimitReached function from codeunit Azure AI Usage instead', '17.0')]
    procedure IsAzureMLLimitReached(ServiceOption: Option; AzureMLUsageLimit: Decimal): Boolean
    begin
        exit(AzureAIUsage.IsLimitReached("Azure AI Service".FromInteger(ServiceOption), AzureMLUsageLimit));
    end;

    [Obsolete('Reference GetTotalProcessingTime function from codeunit Azure AI Usage instead', '17.0')]
    procedure GetTotalProcessingTime(ServiceOption: Option): Decimal
    begin
        exit(AzureAIUsage.GetTotalProcessingTime("Azure AI Service".FromInteger(ServiceOption)));
    end;

    [Obsolete('Reference functions from codeunit Azure AI Usage instead', '17.0')]
    procedure GetSingleInstance(ServiceOption: Option): Boolean
    begin
        exit(AzureAIUsage.GetSingleInstance("Azure AI Service".FromInteger(ServiceOption), Rec));
    end;

    [Obsolete('No need to be part of the API', '17.0')]
    procedure SetTestMode(InputTestDate: Date; InputTestTime: Time)
    begin
        AzureAIUsage.SetTestMode(CreateDateTime(InputTestDate, InputTestTime));
    end;

    [Obsolete('No need to be part of the API', '17.0')]
    procedure HasChangedYear(PreviousDateTime: DateTime): Boolean
    begin
        exit(AzureAIUsage.HasChangedYear(PreviousDateTime));
    end;

    [Obsolete('No need to be part of the API', '17.0')]
    procedure HasChangedMonth(PreviousDateTime: DateTime): Boolean
    begin
        exit(AzureAIUsage.HasChangedMonth(PreviousDateTime));
    end;

    [Obsolete('No need to be part of the API', '17.0')]
    procedure HasChangedDay(PreviousDateTime: DateTime): Boolean
    begin
        exit(AzureAIUsage.HasChangedDay(PreviousDateTime));
    end;

    [Obsolete('No need to be part of the API', '17.0')]
    procedure HasChangedHour(PreviousDateTime: DateTime): Boolean
    begin
        exit(AzureAIUsage.HasChangedHour(PreviousDateTime));
    end;

    [Obsolete('Reference SetImageAnalysisIsSetup function from codeunit Azure AI Usage instead', '17.0')]
    procedure SetImageAnalysisIsSetup(NewValue: Boolean)
    begin
        AzureAIUsage.SetImageAnalysisIsSetup(NewValue);
    end;
}

