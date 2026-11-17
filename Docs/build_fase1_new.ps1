param(
    [string]$JsonPath = "C:\Users\Agents\Documents\3.1proyecto\Docs\fase1_new_content.json",
    [string]$OutPath = "C:\Users\Agents\Documents\3.1proyecto\Docs\Fase 1 NEW. Descuentos y cupones - Juice Corner BD.docx"
)

$ErrorActionPreference = "Stop"

trap {
    Write-Host "ERROR: $($_.Exception.Message)"; Write-Host $_.InvocationInfo.PositionMessage
    if ($null -ne $doc) { try { $doc.Close($false) } catch {} }
    if ($null -ne $word) { try { $word.Quit() } catch {} }
    exit 1
}

function Get-WordColor([string]$hex) {
    $hex = $hex.TrimStart("#")
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
    return ($r + ($g * 256) + ($b * 65536))
}

$DARK      = Get-WordColor "#143D34"
$PRIMARY   = Get-WordColor "#1F6F5C"
$HDR_FILL    = Get-WordColor "#1F5A4A"
$ACCENT    = Get-WordColor "#D99A2B"
$BODY      = Get-WordColor "#26332F"
$MUTED     = Get-WordColor "#5E6F69"
$BORDER    = Get-WordColor "#D7E3DD"
$LIGHT     = Get-WordColor "#F2F7F4"
$ALT       = Get-WordColor "#F8FBF9"
$WHITE     = Get-WordColor "#FFFFFF"
$AMBER_BG  = Get-WordColor "#FBEFE3"
$AMBER_FG  = Get-WordColor "#A85A12"
$GREEN_BG  = Get-WordColor "#EDF5F1"

function Get-EndRange {
    $r = $doc.Paragraphs.Last.Range
    $r.Collapse(0)
    return $r
}

function Shrink-EmptyTail {
    $last = $doc.Paragraphs.Last
    if ($null -ne $last) {
        $txt = $last.Range.Text
        if ($txt -ne $null -and $txt.Trim() -eq "" -and $last.Range.InlineShapes.Count -eq 0 -and -not $last.Range.Information(12)) {
            $last.Range.Font.Size = 2
            $last.Format.SpaceBefore = 0
            $last.Format.SpaceAfter = 0
            $last.Format.LineSpacingRule = 0
        }
    }
}

function Add-Paragraph {
    param(
        [string]$Text = "",
        [string]$Style = "",
        [string]$Font = "Calibri",
        [double]$Size = 0,
        [int]$Bold = -999,
        [int]$Italic = -999,
        [int]$Color = -1,
        [int]$Align = -999,
        [double]$SpaceBefore = -1,
        [double]$SpaceAfter = -1,
        [int]$KeepWithNext = 0,
        [double]$LeftIndent = 0,
        [double]$FirstLineIndent = 0,
        [double]$LineSpacing = 0,
        [int]$PageBreakBefore = 0
    )

    $last = $doc.Paragraphs.Last
    $reuse = $false
    if ($null -ne $last) {
        $txt = $last.Range.Text
        if ($txt -ne $null -and $txt.Trim() -eq "" -and $last.Range.InlineShapes.Count -eq 0 -and -not $last.Range.Information(12)) {
            $reuse = $true
        }
    }
    if ($reuse) {
        $p = $last
    } else {
        $doc.Content.InsertParagraphAfter()
        $p = $doc.Paragraphs.Last
    }

    $p.Range.Font.Reset()
    $p.Format.SpaceBefore = 0
    $p.Format.SpaceAfter = 0
    $p.Format.LeftIndent = 0
    $p.Format.FirstLineIndent = 0
    $p.Format.LineSpacingRule = 0
    $p.Format.Alignment = 0
    $p.Format.KeepWithNext = 0
    $p.Format.KeepTogether = 0
    $p.Format.PageBreakBefore = 0
    $p.Format.WidowControl = -1

    if ($Text -ne "") { $p.Range.InsertBefore($Text) }

    if ($Style -eq "Título 1") {
        $p.Style = $doc.Styles.Item(-2)
    } elseif ($Style -eq "Título 2") {
        $p.Style = $doc.Styles.Item(-3)
    } elseif ($Style -ne "") {
        $p.Style = $doc.Styles.Item($Style)
    }

    $f = $p.Range.Font
    $f.Name = $Font
    if ($Size -gt 0) { $f.Size = $Size }
    if ($Bold -ne -999) { $f.Bold = $Bold }
    if ($Italic -ne -999) { $f.Italic = $Italic }
    if ($Color -ne -1) { $f.Color = $Color }

    if ($Align -ne -999) { $p.Format.Alignment = $Align }
    if ($SpaceBefore -ge 0) { $p.Format.SpaceBefore = $SpaceBefore }
    if ($SpaceAfter -ge 0) { $p.Format.SpaceAfter = $SpaceAfter }
    if ($LeftIndent -ne 0) { $p.Format.LeftIndent = $LeftIndent }
    if ($FirstLineIndent -ne 0) { $p.Format.FirstLineIndent = $FirstLineIndent }
    if ($LineSpacing -gt 0) {
        $p.Format.LineSpacingRule = 5
        $p.Format.LineSpacing = $LineSpacing
    }
    if ($KeepWithNext -ne 0) { $p.Format.KeepWithNext = $KeepWithNext }
    if ($PageBreakBefore -ne 0) { $p.Format.PageBreakBefore = $PageBreakBefore }
    return $p
}

function Add-Callout {
    param(
        [string]$Label,
        [string]$Text,
        [string]$Kind = "green"
    )

    $fill = $GREEN_BG
    $edge = $PRIMARY
    $labelColor = $PRIMARY
    $textColor = $BODY
    if ($Kind -eq "amber") {
        $fill = $AMBER_BG
        $edge = Get-WordColor "#C77C1E"
        $labelColor = $AMBER_FG
    }
    if ($Kind -eq "dark") {
        $fill = $DARK
        $edge = $DARK
        $labelColor = Get-WordColor "#E8B04B"
        $textColor = $WHITE
    }

    Shrink-EmptyTail
    $range = Get-EndRange
    $t = $doc.Tables.Add($range, 1, 1)
    $t.PreferredWidthType = 3
    $t.PreferredWidth = 468
    $t.AllowAutoFit = $false
    $t.Columns.Item(1).Width = 468
    $t.TopPadding = 9
    $t.BottomPadding = 9
    $t.LeftPadding = 13
    $t.RightPadding = 12

    $cell = $t.Cell(1, 1)
    $cell.Shading.BackgroundPatternColor = $fill
    $cell.Range.Text = $Label.ToUpper() + "`r" + $Text

    $p1 = $cell.Range.Paragraphs.Item(1)
    $p1.Range.Font.Reset()
    $p1.Style = $doc.Styles.Item(-1)
    $p1.Range.Font.Name = "Calibri"
    $p1.Range.Font.Size = 8
    $p1.Range.Font.Bold = -1
    $p1.Range.Font.Color = $labelColor
    $p1.Range.Font.Spacing = 1.2
    $p1.Format.SpaceBefore = 0
    $p1.Format.SpaceAfter = 4
    $p1.Format.LineSpacingRule = 0
    $p1.Format.KeepWithNext = -1

    $p2 = $cell.Range.Paragraphs.Item(2)
    $p2.Range.Font.Reset()
    $p2.Style = $doc.Styles.Item(-1)
    $p2.Range.Font.Name = "Calibri"
    $p2.Range.Font.Size = 10.5
    $p2.Range.Font.Color = $textColor
    $p2.Format.SpaceBefore = 0
    $p2.Format.SpaceAfter = 0
    $p2.Format.LineSpacingRule = 5
    $p2.Format.LineSpacing = 12.8
    $p2.Format.Alignment = 0

    $t.Borders.Item(-5).LineStyle = 0
    $t.Borders.Item(-6).LineStyle = 0
    $t.Borders.Item(-1).LineStyle = 0
    $t.Borders.Item(-3).LineStyle = 0
    $t.Borders.Item(-4).LineStyle = 0
    $b = $t.Borders.Item(-2)
    $b.LineStyle = 1
    $b.LineWidth = 24
    $b.Color = $edge
    $b.Visible = $true
}

function Add-DataTable {
    param($Block)

    $caption = Add-Paragraph -Text $Block.caption -Style "JC Caption" -KeepWithNext -1
    $range = Get-EndRange

    $cols = $Block.headers.Count
    $rows = $Block.rows.Count + 1
    $t = $doc.Tables.Add($range, $rows, $cols)
    $t.PreferredWidthType = 3
    $t.PreferredWidth = 468
    $t.AllowAutoFit = $false
    $t.TopPadding = 3
    $t.BottomPadding = 3
    $t.LeftPadding = 5
    $t.RightPadding = 5

    $widths = @()
    foreach ($w in $Block.widths) { $widths += [double]$w }
    $sum = ($widths | Measure-Object -Sum).Sum
    for ($c = 1; $c -le $cols; $c++) {
        $t.Columns.Item($c).Width = ($widths[$c - 1] / $sum) * 468
    }
    $t.PreferredWidthType = 3
    $t.PreferredWidth = 468

    $fs = 8.5
    if ($cols -eq 7) { $fs = 8.0 }
    if ($cols -ge 8) { $fs = 7.5 }

    $alignMap = @{ "l" = 0; "r" = 2; "c" = 1 }

    for ($c = 1; $c -le $cols; $c++) {
        $cell = $t.Cell(1, $c)
        $cell.Range.Text = [string]$Block.headers[$c - 1]
        $cell.Shading.BackgroundPatternColor = $HDR_FILL
        $cell.VerticalAlignment = 1

        $p = $cell.Range.Paragraphs.Item(1)
        $p.Range.Font.Reset()
        $p.Style = $doc.Styles.Item(-1)
        $pf = $p.Format
        $pf.SpaceBefore = 0
        $pf.SpaceAfter = 0
        $pf.LineSpacingRule = 0
        $pf.Alignment = $alignMap[[string]$Block.align[$c - 1]]

        $f = $p.Range.Font
        $f.Name = "Calibri"
        $f.Size = $fs
        $f.Bold = -1
        $f.Color = $WHITE
    }

    for ($r = 2; $r -le $rows; $r++) {
        $rowData = $Block.rows[$r - 2]
        for ($c = 1; $c -le $cols; $c++) {
            $cell = $t.Cell($r, $c)
            $val = [string]$rowData[$c - 1]
            if ($val -eq "") { $val = "—" }
            $cell.Range.Text = $val
            $cell.VerticalAlignment = 1
            if (($r % 2) -eq 1) {
                $cell.Shading.BackgroundPatternColor = $ALT
            }

            $p = $cell.Range.Paragraphs.Item(1)
            $p.Range.Font.Reset()
            $p.Style = $doc.Styles.Item(-1)
            $pf = $p.Format
            $pf.SpaceBefore = 1
            $pf.SpaceAfter = 1
            $pf.LineSpacingRule = 0
            $pf.Alignment = $alignMap[[string]$Block.align[$c - 1]]

            $f = $p.Range.Font
            $f.Name = "Calibri"
            $f.Size = $fs
            $f.Color = $BODY
        }
    }

    $t.Rows.Item(1).HeadingFormat = $true
    $t.Rows.AllowBreakAcrossPages = $false
    if ($rows -le 10) {
        for ($r = 1; $r -lt $rows; $r++) {
            $t.Rows.Item($r).Range.Paragraphs.Format.KeepWithNext = -1
        }
    }

    $t.Borders.Item(-5).LineStyle = 1
    $t.Borders.Item(-5).LineWidth = 4
    $t.Borders.Item(-5).Color = $BORDER
    $t.Borders.Item(-6).LineStyle = 0
    $t.Borders.Item(-1).LineStyle = 1
    $t.Borders.Item(-1).LineWidth = 8
    $t.Borders.Item(-1).Color = $HDR_FILL
    $t.Borders.Item(-3).LineStyle = 1
    $t.Borders.Item(-3).LineWidth = 4
    $t.Borders.Item(-3).Color = $BORDER
    $t.Borders.Item(-2).LineStyle = 0
    $t.Borders.Item(-4).LineStyle = 0

    if ($Block.note -and $Block.note -ne "") {
        Add-Paragraph -Text $Block.note -Style "JC Note" | Out-Null
    }
}

function Add-Figure {
    param($Block)

    $imgPath = Join-Path (Split-Path -Parent $JsonPath) $Block.path
    if (-not (Test-Path -LiteralPath $imgPath)) {
        throw "No se encontró la imagen: $imgPath"
    }

    Shrink-EmptyTail
    $range = Get-EndRange
    $shape = $doc.InlineShapes.AddPicture($imgPath, $false, $true, $range)
    $shape.LockAspectRatio = $true
    $shape.Width = 446
    $shape.AlternativeText = $Block.caption
    $shape.Line.Visible = $true
    $shape.Line.ForeColor.RGB = $BORDER
    $shape.Line.Weight = 0.75

    $p = $shape.Range.Paragraphs.Item(1)
    $p.Format.Alignment = 1
    $p.Format.SpaceBefore = 8
    $p.Format.SpaceAfter = 3
    $p.Format.KeepWithNext = -1

    Add-Paragraph -Text $Block.caption -Style "JC Figure" -Align 1 | Out-Null
}

function Add-List {
    param($Block, [bool]$Numbered)

    $items = @($Block.items)
    for ($i = 0; $i -lt $items.Count; $i++) {
        $marker = "•"
        if ($Numbered) { $marker = "$($i + 1)." }
        $p = Add-Paragraph -Text ($marker + "`t" + [string]$items[$i]) -Style "JC List" -SpaceAfter 3
        $p.Format.LeftIndent = 18
        $p.Format.FirstLineIndent = -12
        $markerRange = $p.Range
        $markerRange.SetRange($p.Range.Start, $p.Range.Start + $marker.Length)
        $markerRange.Font.Color = $ACCENT
        $markerRange.Font.Bold = -1
    }
}

# ---------------------------------------------------------------------------
# Documento
# ---------------------------------------------------------------------------

$jsonText = [System.IO.File]::ReadAllText($JsonPath, [System.Text.Encoding]::UTF8)
$data = $jsonText | ConvertFrom-Json

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$word.ScreenUpdating = $false

$doc = $word.Documents.Add()

$section = $doc.Sections.Item(1)
$section.PageSetup.PageWidth = 612
$section.PageSetup.PageHeight = 792
$section.PageSetup.LeftMargin = 72
$section.PageSetup.RightMargin = 72
$section.PageSetup.TopMargin = 72
$section.PageSetup.BottomMargin = 72
$section.PageSetup.HeaderDistance = 32
$section.PageSetup.FooterDistance = 32

$normal = $doc.Styles.Item(-1)
$normal.Font.Name = "Calibri"
$normal.Font.Size = 10.5
$normal.Font.Color = $BODY
$normal.ParagraphFormat.SpaceBefore = 0
$normal.ParagraphFormat.SpaceAfter = 6
$normal.ParagraphFormat.LineSpacingRule = 5
$normal.ParagraphFormat.LineSpacing = 12.6
$normal.ParagraphFormat.Alignment = 0
$normal.ParagraphFormat.WidowControl = -1

$h1 = $doc.Styles.Item(-2)
$h1.Font.Name = "Calibri"
$h1.Font.Size = 16
$h1.Font.Bold = -1
$h1.Font.Color = $DARK
$h1.ParagraphFormat.SpaceBefore = 20
$h1.ParagraphFormat.SpaceAfter = 8
$h1.ParagraphFormat.KeepWithNext = -1
$h1.ParagraphFormat.KeepTogether = -1
$h1.ParagraphFormat.LineSpacingRule = 0
$hb = $h1.ParagraphFormat.Borders.Item(-3)
$hb.LineStyle = 1
$hb.LineWidth = 8
$hb.Color = $BORDER
$hb.Visible = $true

$h2 = $doc.Styles.Item(-3)
$h2.Font.Name = "Calibri"
$h2.Font.Size = 12.5
$h2.Font.Bold = -1
$h2.Font.Color = $PRIMARY
$h2.ParagraphFormat.SpaceBefore = 14
$h2.ParagraphFormat.SpaceAfter = 4
$h2.ParagraphFormat.KeepWithNext = -1
$h2.ParagraphFormat.KeepTogether = -1
$h2.ParagraphFormat.LineSpacingRule = 0

function Add-CustomStyle {
    param(
        [string]$Name,
        [double]$Size,
        [int]$Bold,
        [int]$Italic,
        [int]$Color,
        [double]$SpaceBefore,
        [double]$SpaceAfter,
        [int]$Align,
        [int]$KeepWithNext,
        [double]$LeftIndent = 0,
        [double]$FirstLineIndent = 0,
        [double]$LineSpacing = 0
    )
    $s = $doc.Styles.Add($Name, 1)
    $s.BaseStyle = $doc.Styles.Item(-1)
    $s.NextParagraphStyle = $doc.Styles.Item(-1)
    $s.Font.Name = "Calibri"
    $s.Font.Size = $Size
    $s.Font.Bold = $Bold
    $s.Font.Italic = $Italic
    $s.Font.Color = $Color
    $s.ParagraphFormat.SpaceBefore = $SpaceBefore
    $s.ParagraphFormat.SpaceAfter = $SpaceAfter
    $s.ParagraphFormat.Alignment = $Align
    $s.ParagraphFormat.KeepWithNext = $KeepWithNext
    $s.ParagraphFormat.WidowControl = -1
    if ($LeftIndent -ne 0) { $s.ParagraphFormat.LeftIndent = $LeftIndent }
    if ($FirstLineIndent -ne 0) { $s.ParagraphFormat.FirstLineIndent = $FirstLineIndent }
    if ($LineSpacing -gt 0) {
        $s.ParagraphFormat.LineSpacingRule = 5
        $s.ParagraphFormat.LineSpacing = $LineSpacing
    } else {
        $s.ParagraphFormat.LineSpacingRule = 0
    }
    return $s
}

Add-CustomStyle -Name "JC Caption" -Size 9 -Bold -1 -Italic 0 -Color $PRIMARY -SpaceBefore 10 -SpaceAfter 3 -Align 0 -KeepWithNext -1 | Out-Null
Add-CustomStyle -Name "JC Note" -Size 8 -Bold 0 -Italic -1 -Color $MUTED -SpaceBefore 2 -SpaceAfter 10 -Align 0 -KeepWithNext 0 -LineSpacing 10 | Out-Null
Add-CustomStyle -Name "JC Figure" -Size 8.5 -Bold 0 -Italic -1 -Color $MUTED -SpaceBefore 0 -SpaceAfter 12 -Align 1 -KeepWithNext 0 -LineSpacing 10.5 | Out-Null
Add-CustomStyle -Name "JC List" -Size 10.5 -Bold 0 -Italic 0 -Color $BODY -SpaceBefore 0 -SpaceAfter 3 -Align 0 -KeepWithNext 0 -LineSpacing 12.6 | Out-Null
Add-CustomStyle -Name "JC Mini" -Size 10 -Bold -1 -Italic 0 -Color $PRIMARY -SpaceBefore 10 -SpaceAfter 3 -Align 0 -KeepWithNext -1 | Out-Null

# Encabezado y pie
$section.PageSetup.DifferentFirstPageHeaderFooter = $false
$hdr = $section.Headers.Item(1)
$hr = $hdr.Range
$hr.Text = "Juice Corner BD  ·  Fase 1 NEW`tDescuentos y cupones · Enero–junio 2026"
$hr.Font.Name = "Calibri"
$hr.Font.Size = 7.5
$hr.Font.Color = $MUTED
$hr.ParagraphFormat.Alignment = 0
$hr.ParagraphFormat.SpaceAfter = 0
$hr.ParagraphFormat.TabStops.Add(468, 2, 0) | Out-Null
$hbr = $hr.ParagraphFormat.Borders.Item(-3)
$hbr.LineStyle = 1
$hbr.LineWidth = 4
$hbr.Color = $BORDER
$hbr.Visible = $true

$footer = $section.Footers.Item(1)
$footer.Range.Text = ""
$r = $footer.Range
$r.SetRange($r.End - 1, $r.End - 1)
$r.InsertBefore("Página ")
$r = $footer.Range
$r.SetRange($r.End - 1, $r.End - 1)
$doc.Fields.Add($r, 33) | Out-Null
$r = $footer.Range
$r.SetRange($r.End - 1, $r.End - 1)
$r.InsertBefore(" de ")
$r = $footer.Range
$r.SetRange($r.End - 1, $r.End - 1)
$doc.Fields.Add($r, 26) | Out-Null
$footer.Range.Font.Name = "Calibri"
$footer.Range.Font.Size = 8
$footer.Range.Font.Color = $MUTED
$footer.Range.ParagraphFormat.Alignment = 1
$footer.Range.ParagraphFormat.SpaceBefore = 0
$footer.Range.ParagraphFormat.SpaceAfter = 0

# Primera página: identidad
$first = $doc.Paragraphs.Item(1)
$first.Range.Text = "FASE 1 NEW  ·  PROYECTO INTEGRADOR I"
$first.Range.Font.Name = "Calibri"
$first.Range.Font.Size = 8
$first.Range.Font.Bold = -1
$first.Range.Font.Color = $ACCENT
$first.Range.Font.Spacing = 1.6
$first.Format.SpaceBefore = 0
$first.Format.SpaceAfter = 10
$first.Format.LineSpacingRule = 0

Add-Paragraph -Text "Descuentos y cupones" -Font "Calibri Light" -Size 30 -Color $DARK -SpaceAfter 4 -LineSpacing 34 | Out-Null
Add-Paragraph -Text $data.subtitle -Size 13 -Color $MUTED -SpaceAfter 8 -LineSpacing 16 | Out-Null
Add-Paragraph -Text $data.meta -Size 8.5 -Color $MUTED -SpaceAfter 12 | Out-Null

$rule = Add-Paragraph -Text "" -Size 2 -SpaceAfter 10
$rb = $rule.Format.Borders.Item(-3)
$rb.LineStyle = 1
$rb.LineWidth = 12
$rb.Color = $ACCENT
$rb.Visible = $true

Add-Callout -Label "Resumen ejecutivo" -Text $data.lead -Kind "green"

# Banda de KPIs
$kpiTitle = Add-Paragraph -Text "INDICADORES CLAVE DEL PERIODO" -Size 8 -Bold -1 -Color $ACCENT -SpaceBefore 12 -SpaceAfter 4
$kpiTitle.Range.Font.Spacing = 1.2
$range = Get-EndRange
$kpi = $doc.Tables.Add($range, 1, 4)
$kpi.PreferredWidthType = 3
$kpi.PreferredWidth = 468
$kpi.AllowAutoFit = $false
$kpi.TopPadding = 8
$kpi.BottomPadding = 8
$kpi.LeftPadding = 7
$kpi.RightPadding = 7
for ($c = 1; $c -le 4; $c++) { $kpi.Columns.Item($c).Width = 117 }

for ($c = 1; $c -le 4; $c++) {
    $item = $data.kpis[$c - 1]
    $cell = $kpi.Cell(1, $c)
    $cell.Shading.BackgroundPatternColor = $LIGHT
    $cell.VerticalAlignment = 1
    $value = [string]$item.value
    if ([string]$item.unit -ne "") { $value = $value + " " + [string]$item.unit }
    $cell.Range.Text = $value + "`r" + ([string]$item.label).ToUpper()
    $p1 = $cell.Range.Paragraphs.Item(1)
    $p1.Range.Font.Reset()
    $p1.Style = $doc.Styles.Item(-1)
    $p1.Range.Font.Name = "Calibri"
    $p1.Range.Font.Size = 17
    $p1.Range.Font.Bold = -1
    $p1.Range.Font.Color = $DARK
    $p1.Format.SpaceBefore = 0
    $p1.Format.SpaceAfter = 2
    $p1.Format.LineSpacingRule = 0
    $p2 = $cell.Range.Paragraphs.Item(2)
    $p2.Range.Font.Reset()
    $p2.Style = $doc.Styles.Item(-1)
    $p2.Range.Font.Name = "Calibri"
    $p2.Range.Font.Size = 7.5
    $p2.Range.Font.Bold = -1
    $p2.Range.Font.Color = $MUTED
    $p2.Format.SpaceBefore = 0
    $p2.Format.SpaceAfter = 0
    $p2.Format.LineSpacingRule = 5
    $p2.Format.LineSpacing = 9.5
}

$kpi.Borders.Item(-5).LineStyle = 0
$kpi.Borders.Item(-6).LineStyle = 1
$kpi.Borders.Item(-6).LineWidth = 4
$kpi.Borders.Item(-6).Color = $BORDER
$kpi.Borders.Item(-1).LineStyle = 1
$kpi.Borders.Item(-1).LineWidth = 12
$kpi.Borders.Item(-1).Color = $ACCENT
$kpi.Borders.Item(-3).LineStyle = 1
$kpi.Borders.Item(-3).LineWidth = 4
$kpi.Borders.Item(-3).Color = $BORDER
$kpi.Borders.Item(-2).LineStyle = 0
$kpi.Borders.Item(-4).LineStyle = 0

$miniLabels = @(
    "Pregunta general.",
    "Preguntas específicas.",
    "Objetivo general.",
    "Objetivos específicos por fase y materia.",
    "Datos que sí están en la base.",
    "Datos que no están y requieren supuesto justificado.",
    "Calidad de datos.",
    "Regla de decisión propuesta.",
    "A.1 Fórmulas del puente de margen.",
    "A.2 Reconciliación de cifras.",
    "A.3 Reproducibilidad."
)

$sectionIndex = 0
foreach ($block in $data.blocks) {
    switch ($block.type) {
        "h1" {
            $p = Add-Paragraph -Text $block.text -Style "Título 1" -KeepWithNext -1
            if ($block.text -like "1.1 *" -or $block.text -like "Anexo A*") {
                $p.Format.PageBreakBefore = -1
            }
            $sectionIndex++
        }
        "h2" {
            Add-Paragraph -Text $block.text -Style "Título 2" -KeepWithNext -1 | Out-Null
        }
        "p" {
            $text = [string]$block.text
            if ($miniLabels -contains $text) {
                Add-Paragraph -Text $text -Style "JC Mini" -KeepWithNext -1 | Out-Null
            } else {
                Add-Paragraph -Text $text -SpaceAfter 6 | Out-Null
            }
        }
        "bullets" {
            Add-List -Block $block -Numbered $false
        }
        "numbered" {
            Add-List -Block $block -Numbered $true
        }
        "callout" {
            $kind = "green"
            if ($block.label -eq "Problema") { $kind = "amber" }
            if ($block.label -eq "Siguiente paso") { $kind = "dark" }
            Add-Callout -Label $block.label -Text $block.text -Kind $kind
        }
        "table" {
            Add-DataTable -Block $block
        }
        "image" {
            Add-Figure -Block $block
        }
        default {
            throw "Tipo de bloque no soportado: $($block.type)"
        }
    }
}

Add-Paragraph -Text "Documento de trabajo · Fase 1 NEW · Octubre de 2026" -Size 8 -Color $MUTED -Align 1 -SpaceBefore 12 -SpaceAfter 0 | Out-Null

foreach ($p in $doc.Paragraphs) {
    if ($p.Range.Text.Trim() -eq "" -and $p.Range.InlineShapes.Count -eq 0) {
        $p.Range.Font.Size = 2
        $p.Format.SpaceBefore = 0
        $p.Format.SpaceAfter = 0
        $p.Format.LineSpacingRule = 0
    }
}

$doc.Content.LanguageID = 1034
$doc.Repaginate()
$doc.Fields.Update() | Out-Null
$section.Footers.Item(1).Range.Fields.Update() | Out-Null
$section.Headers.Item(1).Range.Fields.Update() | Out-Null
$doc.Repaginate()

if (Test-Path -LiteralPath $OutPath) {
    Remove-Item -LiteralPath $OutPath -Force
}

$doc.SaveAs2($OutPath, 16)
$pages = $doc.ComputeStatistics(2)
$words = $doc.ComputeStatistics(0)
Write-Host "Guardado: $OutPath"
Write-Host "Páginas: $pages · Palabras: $words · Tablas: $($doc.Tables.Count) · Imágenes: $($doc.InlineShapes.Count)"

$doc.Close($false)
$word.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
