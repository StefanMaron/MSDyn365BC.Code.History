codeunit 9173 "Profile Helper"
{
    var
        NavDesignerALProfileImporter: DotNet NavDesignerALProfileImporter;
        ProfileConfigurationInputStream: InStream;
        TempFile: File;
        ImportProfileTxt: Label 'Importing profile %1 of %2\Profile: %3', Comment = '%1 and %2 are numbers, %3 is the name of a profile';
        ImportSuccessTxt: Label 'The profile was successfully imported.';

    procedure ImportProfileConfigurationPackage(ServerFileName: Text)
    begin
        // Get profiles.zip from user
        TempFile.Open(ServerFileName);
        TempFile.CreateInStream(ProfileConfigurationInputStream);

        // Load zip file
        NavDesignerALProfileImporter := NavDesignerALProfileImporter.NavDesignerALProfileImporter(ProfileConfigurationInputStream);
    end;

    procedure ReadProfilesFromPackage(var TempProfileImport: Record "Profile Import" temporary; var ImportID: Guid): Boolean
    var
        NavDesignerALProfileReadResponse: DotNet NavDesignerALProfileReadResponse;
    begin
        // Read profiles and report errors
        NavDesignerALProfileReadResponse := NavDesignerALProfileImporter.GetProfiles();
        ImportID := PopulateDesignerDiagnostic(NavDesignerALProfileReadResponse);
        if not NavDesignerALProfileReadResponse.Success() then
            exit(false);

        PopulateProfileImportFromNavDesignerALProfileReadResponse(TempProfileImport, NavDesignerALProfileReadResponse);
        exit(true);
    end;

    /// <summary>
    /// Given a read profile package, this function will import the profiles specified from that package
    /// </summary>
    /// <param name="TempProfileImport"></param>
    /// <returns>Guid representing the import diagnostics ID</returns>
    procedure ImportProfiles(var TempProfileImport: Record "Profile Import" temporary): Guid
    var
        NavDesignerALImportProfileKey: DotNet NavDesignerALImportProfileKey;
        NavDesignerALProfileImportResponse: DotNet NavDesignerALProfileImportResponse;
        ImportProgressDialog: Dialog;
        numProfiles: Integer;
        numProfile: Integer;
        ImportID: Guid;
    begin
        TempProfileImport.Reset();
        TempProfileImport.SetRange(Selected, true);
        ImportID := CreateGuid();
        numProfiles := TempProfileImport.Count();
        if TempProfileImport.FindSet() then
            repeat
                numProfile += 1;
                ImportProgressDialog.Open(StrSubstNo(ImportProfileTxt, numProfile, numProfiles, TempProfileImport."Profile ID"));
                NavDesignerALProfileImportResponse := NavDesignerALProfileImporter.ImportProfile(NavDesignerALImportProfileKey.NavDesignerALImportProfileKey(TempProfileImport."Profile ID", TempProfileImport."App ID"));
                PopulateProfileDesignerDiagnostic(NavDesignerALProfileImportResponse, ImportID);
            until TempProfileImport.Next() = 0;
        ImportProgressDialog.Close();
        exit(ImportID);
    end;

    local procedure PopulateProfileImportFromNavDesignerALProfileReadResponse(var TempProfileImport: Record "Profile Import" temporary; NavDesignerALProfileReadResponse: DotNet NavDesignerALProfileReadResponse)
    var
        NavDesignerALImportProfileKey: DotNet NavDesignerALImportProfileKey;
    begin
        TempProfileImport.Reset();
        TempProfileImport.DeleteAll();
        foreach NavDesignerALImportProfileKey in NavDesignerALProfileReadResponse.ProfilesFound() do begin
            TempProfileImport."App ID" := NavDesignerALImportProfileKey.AppId();
            TempProfileImport."Profile ID" := NavDesignerALImportProfileKey.ProfileId();
            TempProfileImport.Exists := NavDesignerALImportProfileKey.AlreadyExists();
            TempProfileImport.Selected := true; // By default, select the profile for import
            TempProfileImport.Insert();
        end;
    end;

    procedure ShowProfileDiagnostics(DiagnosticsNotification: Notification)
    var
        DesignerDiagnostic: Record "Designer Diagnostic";
        ImportID: Guid;
    begin
        ImportID := DiagnosticsNotification.GetData('ImportID');
        DesignerDiagnostic.SetRange("Operation ID", ImportID);
        DesignerDiagnostic.SetFilter(Severity, '<>%1', Severity::Hidden);
        Page.Run(Page::"Profile Import Diagnostics", DesignerDiagnostic);
    end;

    local procedure PopulateDesignerDiagnostic(NavDesignerALProfileReadResponse: DotNet NavDesignerALProfileReadResponse): guid;
    var
        DesignerDiagnostic: Record "Designer Diagnostic";
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
        ImportID: Guid;
    begin
        ImportID := CreateGuid();
        foreach NavDesignerDiagnostic in NavDesignerALProfileReadResponse.Diagnostics() do begin
            DesignerDiagnostic."Operation ID" := ImportID;
            DesignerDiagnostic."Diagnostics ID" += 1;
            DesignerDiagnostic.Severity := ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            DesignerDiagnostic.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(DesignerDiagnostic.Message));
            DesignerDiagnostic.Insert();
        end;
        DesignerDiagnostic.SetRange("Operation ID", ImportID);
        exit(ImportID);
    end;

    local procedure ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnosticSeverity: DotNet NavDesignerDiagnosticSeverity): Enum Severity;
    begin
        case NavDesignerDiagnosticSeverity of
            NavDesignerDiagnosticSeverity.Error:
                exit(Severity::Error);
            NavDesignerDiagnosticSeverity.Warning:
                exit(Severity::Warning);
            NavDesignerDiagnosticSeverity.Info:
                exit(Severity::Information);
            NavDesignerDiagnosticSeverity.Hidden:
                exit(Severity::Hidden);
        end;
        exit(Severity::Information); // Unknown
    end;

    local procedure PopulateProfileDesignerDiagnostic(NavDesignerALProfileImportResponse: DotNet NavDesignerALProfileImportResponse; ImportID: Guid)
    var
        ProfileDesignerDiagnostic: Record "Profile Designer Diagnostic";
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
    begin
        ProfileDesignerDiagnostic."Import ID" := ImportID;
        ProfileDesignerDiagnostic."Profile App ID" := NavDesignerALProfileImportResponse.ProfileKey().AppId();
        ProfileDesignerDiagnostic."Profile ID" := NavDesignerALProfileImportResponse.ProfileKey().ProfileId();
        ProfileDesignerDiagnostic.Severity := Severity::Hidden; // Make sure at least one Record exist for each profile, in case it was imported with no diagnostics
        ProfileDesignerDiagnostic.Insert(true);
        foreach NavDesignerDiagnostic in NavDesignerALProfileImportResponse.Diagnostics() do begin
            ProfileDesignerDiagnostic."Diagnostics ID" += 1;
            ProfileDesignerDiagnostic.Severity := ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            ProfileDesignerDiagnostic.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(ProfileDesignerDiagnostic.Message));
            ProfileDesignerDiagnostic.Insert(true);
        end;
        if NavDesignerALProfileImportResponse.Success() then begin
            ProfileDesignerDiagnostic."Diagnostics ID" += 1;
            ProfileDesignerDiagnostic.Severity := Severity::Verbose;
            ProfileDesignerDiagnostic.Message := ImportSuccessTxt;
            ProfileDesignerDiagnostic.Insert(true);
        end;
    end;

}
