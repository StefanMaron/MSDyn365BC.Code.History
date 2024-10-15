﻿namespace Microsoft.Intercompany.Dimension;

using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Setup;
using System.IO;
using System.Telemetry;

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
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension name';
                }
                field(Blocked; Rec.Blocked)
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
                    RunPageLink = "Dimension Code" = field(Code);
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
                action("IC Dimension Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Intercompany Dimension Values';
                    Image = Dimensions;
                    RunPageMode = View;
                    ToolTip = 'View or edit the intercompany dimension values for the current intercompany dimension.';

                    trigger OnAction()
                    var
                        PageICDimensionValue: Page "IC Dimension Values";
                    begin
                        PageICDimensionValue.SetDimensionCode(Rec.Code);
                        PageICDimensionValue.Run();
                    end;
                }
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
                    RunObject = Page "IC Dimensions Selector";
                    ToolTip = 'Creates intercompany dimensions from existing dimensions.';
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
                            Message(OnlyAvailableForICUsingDatabaseMsg);
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
                actionref(ICDimensionValues_Promoted; "IC Dimension Values")
                {

                }
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
        RequestUserForFileNameLbl: Label 'Enter the file name.';
        SupportedFileTypesLbl: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        SynchronizeIntercompanyQst: Label 'Partner %1 has been set for the synchronization of intercompany. Do you want to synchronize instead of switching to another partner?', Comment = '%1 = IC Partner code';
        OnlyAvailableForICUsingDatabaseMsg: Label 'Synchronization is only available for companies using a Database for Intercompany. Select this option in the setup if you want to use this action.';

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

