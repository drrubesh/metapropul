# Record structured GRADE judgements

Calculates a final certainty category from reviewer-supplied judgements.
It does not infer GRADE domains from statistical results.

## Usage

``` r
grade_umbrella(
  object,
  starting_certainty,
  risk_of_bias = "not_serious",
  inconsistency = "not_serious",
  indirectness = "not_serious",
  imprecision = "not_serious",
  publication_bias = "not_serious",
  upgrade = "none",
  rationale = NA_character_,
  assessor = NA_character_,
  assessment_date = Sys.Date()
)
```

## Arguments

- object:

  An `umbrella_review` object.

- starting_certainty:

  Starting level (`"high"`, `"moderate"`, `"low"`, or `"very_low"`),
  supplied as a scalar, vector, or column name.

- risk_of_bias, inconsistency, indirectness, imprecision,
  publication_bias:

  Reviewer judgements: `"not_serious"`, `"serious"`, or
  `"very_serious"`.

- upgrade:

  Reviewer-supplied upgrade: `"none"`, `"one"`, or `"two"`.

- rationale:

  Optional scalar, vector, or source-data column recording the
  justification for the certainty judgement.

- assessor:

  Optional assessor name or identifier.

- assessment_date:

  Optional assessment date.

## Value

Review results with GRADE domains and final `GRADE` certainty.
