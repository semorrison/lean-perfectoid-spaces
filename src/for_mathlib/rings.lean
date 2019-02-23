import ring_theory.ideal_operations ring_theory.localization
import for_mathlib.subtype

universes u u₁ u₂ v

namespace localization
open function

def r_iff {R : Type u} [comm_ring R] {S : set R} [is_submonoid S] :
  ∀ x y, r R S x y ↔ ∃ t ∈ S, (x.2.1 * y.1 - y.2.1 * x.1) * t = 0
| ⟨r₁, s₁, hs₁⟩ ⟨r₂, s₂, hs₂⟩ := iff.rfl

local attribute [instance] classical.prop_decidable

variables (R : Type u) [integral_domain R]

def fraction_ring.inc : R → fraction_ring R := λ r, of r (1 : non_zero_divisors R)
variable {R}

instance fraction_ring.inc_is_ring_hom : is_ring_hom (fraction_ring.inc R) :=
by delta fraction_ring.inc; apply_instance

lemma eq_zero_of (r : R) (hr : fraction_ring.inc R r = 0) : r = 0 :=
begin
  replace hr := quotient.exact hr,
  dsimp [(≈), setoid.r] at hr,
  erw r_iff at hr,
  rcases hr with ⟨t, ht, ht'⟩,
  replace ht := ne_zero_of_mem_non_zero_divisors ht,
  change (1 * 0 - (1 * r)) * t = 0 at ht',
  dsimp at ht',
  simpa [ht] using ht'
end

variable (R)
lemma fraction_ring.inc.injective :
  injective (fraction_ring.inc R) :=
(is_add_group_hom.injective_iff _).mpr eq_zero_of

end localization

namespace ideal
open function

@[simp] lemma map_quotient_self {R : Type u} [comm_ring R] (I : ideal R) :
  ideal.map (ideal.quotient.mk I) I = ⊥ :=
lattice.eq_bot_iff.2 $ ideal.map_le_iff_le_comap.2 $
begin
  intros x hx,
  erw submodule.mem_bot I.quotient,
  exact ideal.quotient.eq_zero_iff_mem.2 hx, apply_instance
end

lemma eq_bot_or_top {K : Type u} [discrete_field K] (I : ideal K) :
  I = ⊥ ∨ I = ⊤ :=
begin
  rw classical.or_iff_not_imp_right,
  change _ ≠ _ → _,
  rw ideal.ne_top_iff_one,
  intro h1,
  apply le_antisymm, swap, exact lattice.bot_le,
  intros r hr,
  by_cases H : r = 0,
  simpa,
  simpa [H, h1] using submodule.smul_mem I r⁻¹ hr,
end

lemma eq_bot_of_prime {K : Type u} [discrete_field K] (I : ideal K) [h : I.is_prime] :
  I = ⊥ :=
classical.or_iff_not_imp_right.mp I.eq_bot_or_top h.1

-- This should just be the conjunction of
-- comap f ⊥ = ker f
-- ker f = ⊥  (for injective f)
lemma comap_bot_of_inj {R : Type u} [comm_ring R] {S : Type v} [comm_ring S] (f : R → S) [is_ring_hom f]
(h : injective f) :
  ideal.comap f ⊥ = ⊥ :=
lattice.eq_bot_iff.2 $
begin
  intros r hr,
  change r ∈ f ⁻¹' {0} at hr,
  simp at *,
  apply h,
  rw hr,
  symmetry,
  rw is_ring_hom.map_zero f,
end

end ideal

section
open function localization
local attribute [instance] classical.prop_decidable
noncomputable theory

@[simp] lemma non_zero_divisors_one_val (R : Type*) [integral_domain R] :
  (1 : non_zero_divisors R).val = 1 := rfl

variables {A : Type u₁} [integral_domain A] {B : Type u₂} [integral_domain B]
(f : A → B) [is_ring_hom f] (hf : injective f)
include hf

def frac_map : fraction_ring A → fraction_ring B :=
quotient.lift (λ rs : A × (non_zero_divisors A),
(fraction_ring.inc B $ f rs.1) / (fraction_ring.inc B $ f rs.2.val))
begin
  intros x y hxy,
  dsimp,
  rw div_eq_div_iff,
  { refine quotient.sound _,
    dsimp [(≈), setoid.r] at hxy ⊢,
    erw localization.r_iff at hxy ⊢,
    rcases hxy with ⟨t, ht, ht'⟩,
    use f t,
    fsplit,
    { apply localization.mem_non_zero_divisors_of_ne_zero,
      replace ht := localization.ne_zero_of_mem_non_zero_divisors ht,
      convert ht ∘ (@hf t 0),
      simp [is_ring_hom.map_zero f] },
    { have := congr_arg f ht',
      simp only [is_ring_hom.map_zero f, is_ring_hom.map_mul f, is_ring_hom.map_neg f,
        is_ring_hom.map_add f, is_ring_hom.map_sub f] at this,
      rw ← this,
      ring, -- TODO: why does ring not close this goal?
      simp [mul_comm] } },
  all_goals { intro h,
    replace h := eq_zero_of _ h,
    rw ← is_ring_hom.map_zero f at h,
    replace h := hf h,
    refine localization.ne_zero_of_mem_non_zero_divisors _ h,
    simp }
end

@[simp] lemma frac_map_fraction_ring_inc (a : A) :
  frac_map f hf (fraction_ring.inc A a) = fraction_ring.inc B (f a) :=
begin
  dsimp [frac_map],
  erw quotient.lift_beta,
  simp [is_ring_hom.map_one f],
  exact div_one _,
end

-- set_option trace.class_instances true

@[simp] lemma frac_map_circ_fraction_ring_inc :
  frac_map f hf ∘ (fraction_ring.inc A) = fraction_ring.inc B ∘ f :=
funext $ λ a, frac_map_fraction_ring_inc f hf a

@[simp] lemma frac_map_mk (x : A × (non_zero_divisors A)) :
  frac_map f hf ⟦x⟧ = (fraction_ring.inc B $ f x.1) / (fraction_ring.inc B $ f x.2.val) :=
rfl

instance : is_field_hom (frac_map f hf) :=
{ map_one := by erw [frac_map_fraction_ring_inc f hf 1, is_ring_hom.map_one f]; refl,
  map_mul :=
  begin
    rintros ⟨x⟩ ⟨y⟩,
    repeat {erw frac_map_mk},
    rw div_mul_div,
--    congr,
    rw is_ring_hom.map_mul f,
    rw is_ring_hom.map_mul (fraction_ring.inc B),
    convert rfl,
    rw ←is_ring_hom.map_mul (fraction_ring.inc B),
    rw ←is_ring_hom.map_mul f,
    refl,
  end,
  map_add :=
  begin
    rintros ⟨x⟩ ⟨y⟩,
    repeat {erw frac_map_mk},
    rw div_add_div,
    { /-rw ←is_ring_hom.map_mul (fraction_ring.inc B),
      rw ←is_ring_hom.map_mul (fraction_ring.inc B),
      rw ←is_ring_hom.map_add (fraction_ring.inc B),
      rw is_ring_hom.map_add f,
      convert rfl, -/
      congr' 1,
      { rw [←is_ring_hom.map_mul (fraction_ring.inc B),
        ←is_ring_hom.map_mul (fraction_ring.inc B),
        ←is_ring_hom.map_add (fraction_ring.inc B)],
        congr' 1,
        rw [←is_ring_hom.map_mul f,
        ←is_ring_hom.map_mul f,
        ←is_ring_hom.map_add f],
        congr' 1,
        change (x.snd).val * y.fst + (y.snd).val * x.fst = x.fst * (y.snd).val + (x.snd).val * y.fst,
        simp [add_comm,mul_comm]
      },
      rw ←is_ring_hom.map_mul (fraction_ring.inc B),
      congr' 1,
      rw ←is_ring_hom.map_mul f,
      refl,
    },
    all_goals { intro h,
      replace h := eq_zero_of _ h,
      rw ←is_ring_hom.map_zero f at h,
      replace h := hf h,
      exact localization.ne_zero_of_mem_non_zero_divisors (by simp) h,
    },
  end }

omit hf

def blah (h : A ≃ B) [is_ring_hom h] : is_ring_hom (h.symm) :=
{ map_one := by simp [(is_ring_hom.map_one h).symm],
  map_mul := λ x y,
  begin apply injective_of_left_inverse h.left_inv,
    change h _ = h _,
    simp [is_ring_hom.map_mul h],
  end,
  map_add := λ x y,
  begin apply injective_of_left_inverse h.left_inv,
    change h _ = h _,
    simp [is_ring_hom.map_add h],
  end }

local attribute [instance] blah

lemma fraction_ring_mk_inv : ∀ (x : A × (non_zero_divisors A)),
  @eq (fraction_ring A)
  ⟦x⟧⁻¹ $ if h : x.1 = 0 then 0 else ⟦⟨x.2.val, x.1, mem_non_zero_divisors_of_ne_zero h⟩⟧
| ⟨r,s,hs⟩ := rfl

@[simp] lemma fraction_ring_mk (x : A × (non_zero_divisors A)) :
  @eq (fraction_ring A)
  ⟦x⟧ $ fraction_ring.inc A (x.1) / fraction_ring.inc A ((x.2).val) :=
begin
  simp [fraction_ring.inc, of, (/), algebra.div, fraction_ring_mk_inv],
  rw dif_neg (ne_zero_of_mem_non_zero_divisors x.2.property),
  cases x,
  congr; simp
end

def frac_equiv_frac_of_equiv (h : A ≃ B) [is_ring_hom h] : fraction_ring A ≃ fraction_ring B :=
{ to_fun := frac_map h (injective_of_left_inverse h.left_inv),
  inv_fun := frac_map h.symm (injective_of_left_inverse h.symm.left_inv),
  left_inv :=
  begin
    rintro ⟨x⟩,
    erw frac_map_mk,
    rw is_field_hom.map_div (frac_map _ _),
    symmetry,
    simp [frac_map_fraction_ring_inc],
    exact fraction_ring_mk x,
    apply_instance
  end,
  right_inv :=
  begin
    rintro ⟨x⟩,
    erw frac_map_mk,
    rw is_field_hom.map_div (frac_map _ _),
    symmetry,
    simp [frac_map_fraction_ring_inc],
    exact fraction_ring_mk x,
    apply_instance
  end }

end