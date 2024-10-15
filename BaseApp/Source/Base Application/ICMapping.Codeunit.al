codeunit 428 "IC Mapping"
{

    trigger OnRun()
    begin
    end;

    procedure MapAccounts(ICGLAcc: Record "IC G/L Account")
    var
        GLAcc: Record "G/L Account";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000IIS', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        GLAcc.SetRange("No.", ICGLAcc."No.");
        if GlAcc.FindFirst() and (ICGLAcc."Account Type" = GLAcc."Account Type") then begin
            ICGLAcc."Map-to G/L Acc. No." := GLAcc."No.";
            ICGLAcc.Modify();
        end;
    end;

    procedure MapIncomingICDimensions(ICDimension: Record "IC Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ICDimensionValue: Record "IC Dimension Value";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000IIT', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IIV', GetFeatureTelemetryName(), 'Map Incoming IC Dimensions');

        Dimension.SetRange(Code, ICDimension.Code);
        if Dimension.FindFirst() then begin
            ICDimension."Map-to Dimension Code" := Dimension.Code;
            ICDimension.Modify();
            ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
            if ICDimensionValue.Find('-') then begin
                ICDimensionValue.ModifyAll("Map-to Dimension Code", ICDimension."Map-to Dimension Code");
                if ICDimensionValue.Find('-') then
                    repeat
                        if ICDimensionValue."Map-to Dimension Value Code" = '' then begin
                            DimensionValue.SetRange(Code, ICDimensionValue.Code);
                            if DimensionValue.FindFirst() and
                               (DimensionValue."Dimension Value Type" = ICDimensionValue."Dimension Value Type")
                            then begin
                                ICDimensionValue."Map-to Dimension Value Code" := DimensionValue.Code;
                                ICDimensionValue.Modify();
                            end;
                        end;
                    until ICDimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure MapOutgoingICDimensions(Dimension: Record Dimension)
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        DimensionValue: Record "Dimension Value";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000IIU', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IIW', GetFeatureTelemetryName(), 'Map Outgoing IC Dimensions');

        ICDimension.SetRange(Code, Dimension.Code);
        if ICDimension.FindFirst() then begin
            Dimension."Map-to IC Dimension Code" := ICDimension.Code;
            Dimension.Modify();
            DimensionValue.SetRange("Dimension Code", Dimension.Code);
            if DimensionValue.Find('-') then begin
                DimensionValue.ModifyAll("Map-to IC Dimension Code", Dimension."Map-to IC Dimension Code");
                if DimensionValue.Find('-') then
                    repeat
                        if DimensionValue."Map-to IC Dimension Value Code" = '' then begin
                            ICDimensionValue.SetRange(Code, DimensionValue.Code);
                            if ICDimensionValue.FindFirst() and
                               (DimensionValue."Dimension Value Type" = ICDimensionValue."Dimension Value Type")
                            then begin
                                DimensionValue."Map-to IC Dimension Value Code" := ICDimensionValue.Code;
                                DimensionValue.Modify();
                            end;
                        end;
                    until DimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure GetFeatureTelemetryName(): Text
    begin
        exit('Intercompany');
    end;
}

