page 600 "IC Dimensions"
{
    ApplicationArea = Dimensions;
    Caption = 'Intercompany Dimensions';
    PageType = List;
    SourceTable = "IC Dimension";
    UsageCategory = Administration;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension name';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
#if not CLEAN22
                field("Map-to Dimension Code"; Rec."Map-to Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code of the dimension in your company that this intercompany dimension corresponds to.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Intercompany Dimensions Mapping.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
        }
#if not CLEAN22
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Unused link.';
                ObsoleteTag = '22.0';
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Unused link.';
                ObsoleteTag = '22.0';
            }
        }
#endif
    }

    actions
    {
#if not CLEAN22
        area(navigation)
        {
            group("IC &Dimension")
            {
                Caption = 'IC &Dimension';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Unnecessary grouping';
                ObsoleteTag = '22.0';

                action("IC Dimension &Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'IC Dimension &Values';
                    Image = ChangeDimensions;
                    RunObject = Page "IC Dimension Values";
                    RunPageLink = "Dimension Code" = FIELD(Code);
                    ToolTip = 'View or edit how your company''s dimension values correspond to the dimension values of your intercompany partners.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Intercompany Dimension Mapping.';
                    ObsoleteTag = '22.0';
                }
            }
        }
#endif
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
#if not CLEAN22
                action("Map to Dim. with Same Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Map to Dim. with Same Code';
                    Image = MapDimensions;
                    ToolTip = 'Map the selected intercompany dimensions to dimensions with the same code.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Intercompany Chart of Accounts Mapping.';
                    ObsoleteTag = '22.0';

                    trigger OnAction()
                    var
                        ICMappingDimensions: Page "IC Mapping Dimension";
                    begin
                        ICMappingDimensions.RunModal();
                    end;
                }
#endif
                action(OpenDimensionsMapping)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Dimensions Mapping';
                    Image = Intercompany;
                    RunObject = Page "IC Mapping Dimension";
                    ToolTip = 'Open the mapping between the intercompany dimensions and the dimensions of the current company.';
                }
                action(CopyFromDimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Copy from Dimensions';
                    Image = CopyDimensions;
                    ToolTip = 'Creates intercompany dimensions for existing dimensions.';

                    trigger OnAction()
                    begin
                        CopyFromDimensionsToICDim();
                    end;
                }
                separator(Action14)
                {
                }
                action(Import)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import intercompany dimensions from a file.';

                    trigger OnAction()
                    begin
                        ImportFromXML();
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export intercompany dimensions to a file.';

                    trigger OnAction()
                    begin
                        ExportToXML();
                    end;
                }
                action(SynchronizationSetup)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Synchronization Setup';
                    Image = Setup;
                    ShortcutKey = 'S';
                    ToolTip = 'Open the setup for the synchronization of the dimensions of intercompany.';
                    Enabled = EnableSynchronization;

                    trigger OnAction()
                    var
                        ICSetup: Record "IC Setup";
                        ICMapping: Codeunit "IC Mapping";
                        ICDimensionsSetup: Page "IC Dimensions Setup";
                        ICPartnerCode: Code[20];
                    begin
                        ICSetup.FindFirst();
                        if ICSetup."IC Inbox Type" <> ICSetup."IC Inbox Type"::Database then begin
                            Message(OnlyAvailableForICUsingDatabase);
                            exit;
                        end;
                        ICPartnerCode := ICSetup."Partner Code for Acc. Syn.";
                        if (ICPartnerCode <> '') then
                            if Confirm(StrSubstNo(SynchronizeIntercompanyQst, ICPartnerCode), true) then begin
                                ICMapping.SynchronizeDimensions(false, ICPartnerCode);
                                exit;
                            end;
                        ICDimensionsSetup.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
#if not CLEAN22
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
#endif      
            group(Category_Category4)
            {
                Caption = 'Dimensions', Comment = 'Generated from the PromotedActionCategories property index 3.';

#if not CLEAN22
                actionref("Map to Dim. with Same Code_Promoted"; "Map to Dim. with Same Code")
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Intercompany Dimensions Mapping.';
                    ObsoleteTag = '22.0';
                }
#endif      
                actionref(OpenDimensionsMapping_Promoted; OpenDimensionsMapping)
                {
                }
                actionref(CopyFromDimensions_Promoted; CopyFromDimensions)
                {
                }
                actionref(SynchronizationSetup_Promoted; SynchronizationSetup)
                {
                }
#if not CLEAN22
                actionref("IC Dimension &Values_Promoted"; "IC Dimension &Values")
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Intercompany Dimension Values Mapping.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Category5)
            {
                Caption = 'Import/Export', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Import_Promoted; Import)
                {
                }
                actionref("E&xport_Promoted"; "E&xport")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ICSetup: Record "IC Setup";
    begin
        if ICSetup.FindFirst() then
            EnableSynchronization := (ICSetup."IC Inbox Type" = ICSetup."IC Inbox Type"::Database);
    end;

    var
        EnableSynchronization: Boolean;
        SelectFileToImportLbl: Label 'Select file to import into the dimensions of intercompany.';
        DefaultNameForExportFileLbl: Label 'ICDimensions.xml';
        CopyFromDimensionsQst: Label 'Are you sure you want to copy from Dimensions?';
        RequestUserForFileNameLbl: Label 'Enter the file name.';
        SupportedFileTypesLbl: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        SynchronizeIntercompanyQst: Label 'Partner %1 has been set for the synchronization of intercompany. Do you want to synchronize instead of switching to another partner?', Comment = '%1 = IC Partner code';
        OnlyAvailableForICUsingDatabase: Label 'Synchronization is only available for companies using a Database for Intercompany. Select this option in the setup if you want to use this action.';

    local procedure CopyFromDimensionsToICDim()
    var
        Dim: Record Dimension;
        DimVal: Record "Dimension Value";
        ICDim: Record "IC Dimension";
        ICDimVal: Record "IC Dimension Value";
        ConfirmManagement: Codeunit "Confirm Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDimValEmpty: Boolean;
        ICDimValExists: Boolean;
        PrevIndentation: Integer;
    begin
        if not ConfirmManagement.GetResponseOrDefault(CopyFromDimensionsQst, true) then
            exit;

        FeatureTelemetry.LogUptake('0000IL2', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        ICDimVal.LockTable();
        ICDim.LockTable();
        Dim.SetRange(Blocked, false);
        if Dim.Find('-') then
            repeat
                if not ICDim.Get(Dim.Code) then begin
                    ICDim.Init();
                    ICDim.Code := Dim.Code;
                    ICDim.Name := Dim.Name;
                    ICDim.Insert();
                end;

                ICDimValExists := false;
                DimVal.SetRange("Dimension Code", Dim.Code);
                ICDimVal.SetRange("Dimension Code", Dim.Code);
                ICDimValEmpty := not ICDimVal.FindFirst();
                if DimVal.Find('-') then
                    repeat
                        if DimVal."Dimension Value Type" = DimVal."Dimension Value Type"::"End-Total" then
                            PrevIndentation := PrevIndentation - 1;
                        if not ICDimValEmpty then
                            ICDimValExists := ICDimVal.Get(DimVal."Dimension Code", DimVal.Code);
                        if not ICDimValExists and not DimVal.Blocked then begin
                            ICDimVal.Init();
                            ICDimVal."Dimension Code" := DimVal."Dimension Code";
                            ICDimVal.Code := DimVal.Code;
                            ICDimVal.Name := DimVal.Name;
                            ICDimVal."Dimension Value Type" := DimVal."Dimension Value Type";
                            ICDimVal.Indentation := PrevIndentation;
                            ICDimVal.Insert();
                        end;
                        PrevIndentation := ICDimVal.Indentation;
                        if DimVal."Dimension Value Type" = DimVal."Dimension Value Type"::"Begin-Total" then
                            PrevIndentation := PrevIndentation + 1;
                    until DimVal.Next() = 0;
            until Dim.Next() = 0;
    end;

    local procedure ImportFromXML()
    var
        ICSetup: Record "IC Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDimIO: XMLport "IC Dimension Import/Export";
        IFile: File;
        IStr: InStream;
        FileName: Text[1024];
        StartFileName: Text[1024];
    begin
        ICSetup.Get();

        StartFileName := ICSetup."IC Inbox Details";
        if StartFileName <> '' then begin
            if StartFileName[StrLen(StartFileName)] <> '\' then
                StartFileName := StartFileName + '\';
            StartFileName := StartFileName + '*.xml';
        end;

        if not Upload(SelectFileToImportLbl, '', SupportedFileTypesLbl, StartFileName, FileName) then
            Error(RequestUserForFileNameLbl);

        FeatureTelemetry.LogUptake('0000IL3', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        IFile.Open(FileName);
        IFile.CreateInStream(IStr);
        ICDimIO.SetSource(IStr);
        ICDimIO.Import();
    end;

    local procedure ExportToXML()
    var
        ICSetup: Record "IC Setup";
        FileMgt: Codeunit "File Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        ICDimIO: XMLport "IC Dimension Import/Export";
        OFile: File;
        OStr: OutStream;
        FileName: Text;
        DefaultFileName: Text;
    begin
        ICSetup.Get();

        DefaultFileName := ICSetup."IC Inbox Details";
        if DefaultFileName <> '' then
            if DefaultFileName[StrLen(DefaultFileName)] <> '\' then
                DefaultFileName := DefaultFileName + '\';
        DefaultFileName := DefaultFileName + DefaultNameForExportFileLbl;

        FileName := FileMgt.ServerTempFileName('xml');
        if FileName = '' then
            exit;

        FeatureTelemetry.LogUptake('0000IL4', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        OFile.Create(FileName);
        OFile.CreateOutStream(OStr);
        ICDimIO.SetDestination(OStr);
        ICDimIO.Export();
        OFile.Close();
        Clear(OStr);

        Download(FileName, 'Export', TemporaryPath, '', DefaultFileName);
    end;
}

