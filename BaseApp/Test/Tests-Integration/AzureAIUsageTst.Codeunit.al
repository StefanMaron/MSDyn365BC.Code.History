codeunit 135202 "Azure AI Usage Tst"
{
    Permissions = TableData "Azure AI Usage" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Azure AI Usage Service Usage]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        ProcessingTimeLessThanZeroErr: Label 'The available Azure Machine Learning processing time is less than or equal to zero.';
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

    [Test]
    [Scope('OnPrem')]
    procedure AzureMLProcessingTimeDoesNotExceedLimit()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ProcessingTime: Decimal;
    begin
        // [SCENARIO] Azure Machine Learning Processing time does not exceeds AzureML limit
        // [GIVEN] AzureMachineLearningUsage > 0
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;

        ProcessingTime := LibraryRandom.RandDec(1000, 2);
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Machine Learning",
          ProcessingTime);

        // [WHEN] When IsAzureMLLimitReached is invoked with Limit smaller than Processing time
        // [THEN] The function returns FALSE
        Assert.IsFalse(AzureAIUsage.IsAzureMLLimitReached(AzureAIUsage.Service::"Machine Learning",
            ProcessingTime + 1),
          'HasAzureLimitReached returns wrong value when Processing time does not exceeds Limit.');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AzureMLProcessingTimeExceedsLimit()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ProcessingTime: Decimal;
    begin
        // [SCENARIO] Azure Machine Learning Processing time exceeds AzureML limit
        // [GIVEN] AzureMachineLearningUsage > 0
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;

        ProcessingTime := LibraryRandom.RandDec(1000, 2);
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Machine Learning",
          ProcessingTime);

        // [WHEN] When IsAzureMLLimitReached is invoked with Limit bigger than Processing time
        // [THEN] HasAzureLimitReached returns TRUE
        Assert.IsTrue(AzureAIUsage.IsAzureMLLimitReached(AzureAIUsage.Service::"Machine Learning",
            ProcessingTime - 1),
          'HasAzureLimitReached returns wrong value when Processing time exceeds Limit.');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AzureMLProcessingTimeIsResetMonthly()
    var
        AzureAIUsage: Record "Azure AI Usage";
        NewLastUpdated: DateTime;
    begin
        // [SCENARIO] Total Processing time is reset when Azure ML related feature is called first time in current month
        // [GIVEN] Time Processing Time > 0 and Last Date Updated is in previous month
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;

        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Machine Learning",
          LibraryRandom.RandDec(1000, 2));

        // [WHEN] When Azure AI Usage is retrieved
        NewLastUpdated := CreateDateTime(CalcDate('<-1M>', Today), 0T);
        LibraryLowerPermissions.SetOutsideO365Scope;
        AzureAIUsage.Validate("Last DateTime Updated", NewLastUpdated);
        AzureAIUsage.Modify(true);

        // [THEN] The Last updated datetime has been updated
        LibraryLowerPermissions.SetO365Basic;
        AzureAIUsage.Get(AzureAIUsage.Service::"Machine Learning");
        Assert.AreEqual(NewLastUpdated, AzureAIUsage."Last DateTime Updated", 'Last date time not set');

        // [THEN] Ensure that the limit period is of type Month
        Assert.AreEqual(AzureAIUsage."Limit Period"::Month, AzureAIUsage."Limit Period", 'Incorrect limit period');

        // [THEN] Total Processing Time is reset to 0
        Assert.AreEqual(0, AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Machine Learning"),
          '');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AzureMLProcessingTimeIsNotResetWithinSameMonth()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ProcessingTime: Decimal;
    begin
        // [SCENARIO] Total Processing time is reset when Azure ML related feature is called first time in current month
        // [GIVEN] Time Processing Time > 0 and Last Date Updated is in current month
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;

        ProcessingTime := LibraryRandom.RandDec(1000, 2);
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Machine Learning",
          ProcessingTime);

        // [WHEN] When Azure AI Usage is retrieved
        LibraryLowerPermissions.SetOutsideO365Scope;

        // [THEN] Total Processing Time is not reset to 0
        LibraryLowerPermissions.SetO365Basic;
        Assert.AreEqual(
          ProcessingTime, AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Machine Learning"),
          '');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastUpdatedDateIsTodayWhenInsertRecord()
    var
        AzureAIUsage: Record "Azure AI Usage";
        NowDateTime: DateTime;
    begin
        // [SCENARIO] If Azure AI Usage record does not exist, when get record
        // Last Date Updated is set to TODAY
        // [GIVEN] Azure AI Usage record does not exist
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;
        NowDateTime := CurrentDateTime;
        AzureAIUsage.SetTestMode(DT2Date(NowDateTime), DT2Time(NowDateTime));

        // [WHEN] Get Azure AI Usage record
        AzureAIUsage.GetSingleInstance(AzureAIUsage.Service::"Machine Learning");

        // [THEN] Last Date Updated is set to the current date time
        Assert.IsTrue(AzureAIUsage."Last DateTime Updated" = NowDateTime,
          'Last DateTime Updated is not set to now');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AzureMLProcessingTimeCannotBeDecreased()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        // [SCENARIO] Azure Machine Learning Processing time cannot be decreased

        // [GIVEN] No instance of Azure AI Usage
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;

        // [WHEN]  When negative amount of time is added
        // [THEN]  IncrementTotalProcessingTime throws Error
        asserterror AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Machine Learning",
            -LibraryRandom.RandDec(100, 2));
        Assert.ExpectedError(ProcessingTimeLessThanZeroErr);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AzureAIUsageCannotbeInstantiatedOnPremise()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        // [SCENARIO] Azure AI Usage record cannot be Instantiated OnPremise

        // [GIVEN] No instance of Azure AI Usage and OnPremise
        Initialize;
        LibraryLowerPermissions.SetOutsideO365Scope;
        LibraryLowerPermissions.SetO365Basic;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN]  When get instance
        // [THEN] FALSE is returned by GetSingleInstance function
        Assert.IsFalse(AzureAIUsage.GetSingleInstance(AzureAIUsage.Service::"Machine Learning"),
          'Azure AI Usage can be instantiated OnPremise');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure Initialize()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnsureThatMockDataIsFetchedFromKeyVault;
        AzureAIUsage.DeleteAll;
    end;

    local procedure EnsureThatMockDataIsFetchedFromKeyVault()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
    begin
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(StrSubstNo('machinelearning-%1', TenantId),
          LibraryUtility.GetInetRoot + '\App\Test\Files\AzureKeyVaultSecret\AzureAIUsageSecret.txt');
        MockAzureKeyvaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', 'machinelearning');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('machinelearning',
          LibraryUtility.GetInetRoot + '\App\Test\Files\AzureKeyVaultSecret\AzureAIUsageSecret.txt');
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;
}

