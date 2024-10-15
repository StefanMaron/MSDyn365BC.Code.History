page 600 "IC Dimensions"
{
    ApplicationArea = Dimensions;
    Caption = 'Intercompany Dimensions';
    PageType = List;
    SourceTable = "IC Dimension";
    UsageCategory = Administration;

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
                field(Name; Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension name';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to Dimension Code"; Rec."Map-to Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code of the dimension in your company that this intercompany dimension corresponds to.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("IC &Dimension")
            {
                Caption = 'IC &Dimension';
                action("IC Dimension &Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'IC Dimension &Values';
                    Image = ChangeDimensions;
                    RunObject = Page "IC Dimension Values";
                    RunPageLink = "Dimension Code" = FIELD(Code);
                    ToolTip = 'View or edit how your company''s dimension values correspond to the dimension values of your intercompany partners.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Map to Dim. with Same Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Map to Dim. with Same Code';
                    Image = MapDimensions;
                    ToolTip = 'Map the selected intercompany dimensions to dimensions with the same code.';

                    trigger OnAction()
                    var
                        ICDimension: Record "IC Dimension";
                        ICMapping: Codeunit "IC Mapping";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        CurrPage.SetSelectionFilter(ICDimension);
                        if ICDimension.Find('-') and ConfirmManagement.GetResponseOrDefault(Text000, true) then
                            repeat
                                ICMapping.MapIncomingICDimensions(ICDimension);
                            until ICDimension.Next() = 0;
                    end;
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
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Dimensions', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Map to Dim. with Same Code_Promoted"; "Map to Dim. with Same Code")
                {
                }
                actionref(CopyFromDimensions_Promoted; CopyFromDimensions)
                {
                }
                actionref("IC Dimension &Values_Promoted"; "IC Dimension &Values")
                {
                }
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

    var
        Text000: Label 'Are you sure you want to map the selected lines?';
        Text001: Label 'Select file to import into %1';
        Text002: Label 'ICDim.xml';
        Text004: Label 'Are you sure you want to copy from Dimensions?';
        Text005: Label 'Enter the file name.';
        Text006: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';

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
        if not ConfirmManagement.GetResponseOrDefault(Text004, true) then
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

        if not Upload(StrSubstNo(Text001, TableCaption), '', Text006, StartFileName, FileName) then
            Error(Text005);

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
        DefaultFileName := DefaultFileName + Text002;

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

