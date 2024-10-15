page 31085 "Acc. Schedule Filter Lines"
{
    AutoSplitKey = true;
    Caption = 'Acc. Schedule Filter Lines';
    DataCaptionFields = "Export Acc. Schedule Name";
    PageType = List;
    SourceTable = "Acc. Schedule Filter Line";

    layout
    {
        area(content)
        {
            repeater(Control1100156000)
            {
                ShowCaption = false;
                field(Show; Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if vat statement line will be show';
                }
                field("Empty Column"; "Empty Column")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the empty column';
                }
                field(Dim1Filter; "Dimension 1 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FormGetCaptionClass(1);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    ToolTip = 'Specifies the filter for dimension 1.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(FormLookUpDimFilter(AnalysisView."Dimension 1 Code", Text));
                    end;
                }
                field(Dim2Filter; "Dimension 2 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FormGetCaptionClass(2);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    ToolTip = 'Specifies the filter for dimension 2.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(FormLookUpDimFilter(AnalysisView."Dimension 2 Code", Text));
                    end;
                }
                field(Dim3Filter; "Dimension 3 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FormGetCaptionClass(3);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    ToolTip = 'Specifies the filter for dimension 3.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(FormLookUpDimFilter(AnalysisView."Dimension 3 Code", Text));
                    end;
                }
                field(Dim4Filter; "Dimension 4 Filter")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FormGetCaptionClass(4);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    ToolTip = 'Specifies the filter for dimension 4.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(FormLookUpDimFilter(AnalysisView."Dimension 4 Code", Text));
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        if AccSchedName.Get(ExportAccSchedule."Account Schedule Name") then
            if AccSchedName."Analysis View Name" <> '' then
                AnalysisView.Get(AccSchedName."Analysis View Name")
            else begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

        Dim1FilterEnable := AnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := AnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := AnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := AnalysisView."Dimension 4 Code" <> '';
    end;

    var
        AnalysisView: Record "Analysis View";
        ExportAccSchedule: Record "Export Acc. Schedule";
        GLSetup: Record "General Ledger Setup";
        AccSchedName: Record "Acc. Schedule Name";
        [InDataSet]
        Dim1FilterEnable: Boolean;
        [InDataSet]
        Dim2FilterEnable: Boolean;
        [InDataSet]
        Dim3FilterEnable: Boolean;
        [InDataSet]
        Dim4FilterEnable: Boolean;

    [Scope('OnPrem')]
    procedure FormGetCaptionClass(DimNo: Integer): Text[250]
    begin
        exit(AnalysisView.GetCaptionClass(DimNo));
    end;

    [Scope('OnPrem')]
    procedure SetParameter(ExportAccSchedFrom: Record "Export Acc. Schedule")
    begin
        ExportAccSchedule := ExportAccSchedFrom;
    end;

    [Scope('OnPrem')]
    procedure FormLookUpDimFilter(Dim: Code[20]; var Text: Text[1024]): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter;
            exit(true);
        end;
        exit(false);
    end;
}

