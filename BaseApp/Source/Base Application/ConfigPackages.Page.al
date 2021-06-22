page 8615 "Config. Packages"
{
    AdditionalSearchTerms = 'rapidstart rapid start implementation migrate setup packages';
    ApplicationArea = Suite;
    Caption = 'Configuration Packages';
    CardPageID = "Config. Package Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage,Package';
    SourceTable = "Config. Package";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the configuration package.';
                }
                field("Package Name"; "Package Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the package.';
                }
                field("Language ID"; "Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the Windows language to use for the configuration package. Choose the field and select a language ID from the list.';
                }
                field("Product Version"; "Product Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the product that you are configuring. You can use this field to help differentiate among various versions of a solution.';
                }
                field("Processing Order"; "Processing Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order in which the package is to be processed.';
                }
                field("Exclude Config. Tables"; "Exclude Config. Tables")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to exclude configuration tables from the package. Select the check box to exclude these types of tables.';
                }
                field("No. of Tables"; "No. of Tables")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of tables that the package contains.';
                }
                field("No. of Records"; "No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of records in the package.';
                }
                field("No. of Errors"; "No. of Errors")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of errors that the package contains.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Package)
            {
                Caption = 'Package';

                action(GetTables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Tables';
                    Ellipsis = true;
                    Image = GetLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Select tables that you want to add to the configuration package.';

                    trigger OnAction()
                    var
                        GetPackageTables: Report "Get Package Tables";
                    begin
                        CurrPage.SaveRecord;
                        GetPackageTables.Set(Code);
                        GetPackageTables.RunModal;
                        Clear(GetPackageTables);
                    end;
                }

                action(ExportPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Package';
                    Ellipsis = true;
                    Enabled = AditionalOptionsEnabled;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create a .rapidstart file that which delivers the package contents in a compressed format. Configuration questionnaires, configuration templates, and the configuration worksheet are added to the package automatically unless you specifically decide to exclude them.';

                    trigger OnAction()
                    begin
                        TestField(Code);
                        ConfigXMLExchange.ExportPackage(Rec);
                    end;
                }
                action(ImportPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Package';
                    Ellipsis = true;
                    Enabled = AditionalOptionsEnabled;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import a .rapidstart package file.';

                    trigger OnAction()
                    begin
                        ConfigXMLExchange.ImportPackageXMLFromClient;
                    end;
                }
                action(ImportPredefinedPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Predefined Package';
                    Ellipsis = true;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import one of the preloaded files with packages, such as Evaluation or Standard.';
                    Visible = ImportPredefinedPackageVisible;

                    trigger OnAction()
                    var
                        ConfigurationPackageFile: Record "Configuration Package File";
                        TempBlob: Codeunit "Temp Blob";
                        TempBlobUncompressed: Codeunit "Temp Blob";
                        ConfigurationPackageFiles: Page "Configuration Package Files";
                        InStream: InStream;
                    begin
                        ConfigurationPackageFiles.LookupMode(true);
                        if ConfigurationPackageFiles.RunModal <> ACTION::LookupOK then
                            exit;

                        ConfigurationPackageFiles.GetRecord(ConfigurationPackageFile);
                        TempBlob.FromRecord(ConfigurationPackageFile, ConfigurationPackageFile.FieldNo(Package));
                        ConfigXMLExchange.DecompressPackageToBlob(TempBlob, TempBlobUncompressed);
                        TempBlobUncompressed.CreateInStream(InStream);
                        ConfigXMLExchange.ImportPackageXMLFromStream(InStream);
                    end;
                }
                action(ExportToExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Excel';
                    Enabled = AditionalOptionsEnabled;
                    Image = ExportToExcel;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Export the data in the package to Excel.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        TestField(Code);

                        ConfigPackageTable.SetRange("Package Code", Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, Code), true) then
                            ConfigExcelExchange.ExportExcelFromTables(ConfigPackageTable);
                    end;
                }
                action(ImportFromExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import from Excel';
                    Enabled = AditionalOptionsEnabled;
                    Image = ImportExcel;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Begin the migration of legacy data.';

                    trigger OnAction()
                    var
                        ConfigExcelExchange: Codeunit "Config. Excel Exchange";
                    begin
                        ConfigExcelExchange.ImportExcelFromPackage;
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';

                action(ApplyPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Package';
                    Image = Apply;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import the configuration package and apply the package database data at the same time.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfigPackageMgt: Codeunit "Config. Package Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        TestField(Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text003, Code), true) then begin
                            ConfigPackageTable.SetRange("Package Code", Code);
                            ConfigPackageMgt.ApplyPackage(Rec, ConfigPackageTable, true);
                        end;
                    end;
                }
                action(CopyPackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Package';
                    Image = CopyWorksheet;
                    ToolTip = 'Copy an existing configuration package to create a new package based on the same content.';

                    trigger OnAction()
                    var
                        CopyPackage: Report "Copy Package";
                    begin
                        TestField(Code);
                        CopyPackage.Set(Rec);
                        CopyPackage.RunModal;
                        Clear(CopyPackage);
                    end;
                }
                action(ValidatePackage)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Package';
                    Image = CheckRulesSyntax;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Determine if you have introduced errors, such as not including tables that the configuration relies on.';

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ActiveSession: Record "Active Session";
                        SessionEvent: Record "Session Event";
                        ConfigProgressBar: Codeunit "Config. Progress Bar";
                        ConfirmManagement: Codeunit "Confirm Management";
                        Canceled: Boolean;
                    begin
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, "Package Name"), true) then begin
                            ConfigPackageTable.SetRange("Package Code", Code);
                            ConfigProgressBar.Init(ConfigPackageTable.Count, 1, ValidatingTableRelationsMsg);

                            BackgroundSessionId := 0;
                            StartSession(BackgroundSessionId, CODEUNIT::"Config. Validate Package", CompanyName, ConfigPackageTable);

                            ConfigPackageTable.SetRange(Validated, false);
                            ConfigPackageTable.SetCurrentKey("Package Processing Order", "Processing Order");

                            Sleep(1000);
                            while not Canceled and ActiveSession.Get(ServiceInstanceId, BackgroundSessionId) and ConfigPackageTable.FindFirst do begin
                                ConfigPackageTable.CalcFields("Table Name");
                                Canceled := not ConfigProgressBar.UpdateCount(ConfigPackageTable."Table Name", ConfigPackageTable.Count);
                                Sleep(1000);
                            end;

                            if ActiveSession.Get(ServiceInstanceId, BackgroundSessionId) then
                                StopSession(BackgroundSessionId, ValidationCanceledMsg);

                            if not Canceled and ConfigPackageTable.FindFirst then begin
                                SessionEvent.SetAscending("Event Datetime", true);
                                SessionEvent.SetRange("User ID", UserId);
                                SessionEvent.SetRange("Server Instance ID", ServiceInstanceId);
                                SessionEvent.SetRange("Session ID", BackgroundSessionId);
                                SessionEvent.FindLast;
                                Message(SessionEvent.Comment);
                            end;

                            ConfigProgressBar.Close;
                        end;
                    end;
                }
                action(ExportToTranslation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to Translation';
                    Image = Export;
                    ToolTip = 'Export the data to a file that is suited translation.';
                    Visible = false;

                    trigger OnAction()
                    var
                        ConfigPackageTable: Record "Config. Package Table";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        TestField(Code);
                        ConfigXMLExchange.SetAdvanced(true);
                        ConfigPackageTable.SetRange("Package Code", Code);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, Code), true) then
                            ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, '');
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ConfigurationPackageFile: Record "Configuration Package File";
        ConfigPackage: Record "Config. Package";
    begin
        ImportPredefinedPackageVisible := not ConfigurationPackageFile.IsEmpty;
        AditionalOptionsEnabled := ConfigPackage.WritePermission;
    end;

    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        Text002: Label 'Validate package %1?';
        Text003: Label 'Apply data from package %1?';
        Text004: Label 'Export package %1?';
        ValidatingTableRelationsMsg: Label 'Validating table relations';
        ValidationCanceledMsg: Label 'Validation canceled.';
        BackgroundSessionId: Integer;
        ImportPredefinedPackageVisible: Boolean;
        AditionalOptionsEnabled: Boolean;
}

