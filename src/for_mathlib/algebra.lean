import ring_theory.algebra_operations
import ring_theory.localization

import tactic.tidy

import for_mathlib.rings

local attribute [instance] set.pointwise_mul_semiring

namespace localization
variables {R : Type*} [comm_ring R] (s : set R) [is_submonoid s]

instance : algebra R (localization R s) :=
algebra.of_ring_hom of (by apply_instance)

end localization

namespace algebra

section span_mul
open submodule
variables {R : Type*} {A : Type*} [comm_ring R] [ring A] [algebra R A]
variables (M : submodule R A)

lemma mul_left_span_singleton_eq_image (a : A) :
  span R {a} * M = map (lmul_left R A a) M :=
begin
  apply le_antisymm,
  { rw mul_le,
    intros a' ha' m hm,
    rw mem_span_singleton at ha',
    rcases ha' with ⟨r, rfl⟩,
    use [r • m, M.smul_mem r hm],
    simp },
  { rintros _ ⟨m, hm, rfl⟩,
    apply mul_mem_mul _ hm,
    apply subset_span,
    simp }
end

lemma mul_left_span_singleton_eq_image' (a : A) : ↑(span _ {a} * M) = (*) a '' M :=
congr_arg submodule.carrier (mul_left_span_singleton_eq_image M a)

end span_mul

section to_linear_map
variables {R : Type*} {A : Type*} {B : Type*} {C : Type*}
variables [comm_ring R] [ring A] [ring B] [ring C]
variables [algebra R A] [algebra R B] [algebra R C]

@[simp] lemma to_linear_map_comp (f : A →ₐ[R] B) (g : B →ₐ[R] C) :
  (g.comp f).to_linear_map = g.to_linear_map.comp f.to_linear_map := rfl

end to_linear_map

section
variables {R : Type*} [comm_ring R]
variables {A : Type*} [ring A] [algebra R A]
variables {B : Type*} [ring B] [algebra R B]
variables (f : A →ₐ[R] B)

lemma map_lmul_left (a : A) :
  f ∘ (lmul_left R A a) = (lmul_left R B (f a)) ∘ f :=
funext $ λ b, f.map_mul a b

lemma lmul_left_mul (a b : A) :
  lmul_left R A (a * b) = (lmul_left R A a).comp (lmul_left R A b) :=
linear_map.ext $ λ _, mul_assoc _ _ _

instance : is_monoid_hom (lmul_left R A) :=
{ map_one := linear_map.ext $ λ _, one_mul _,
  map_mul := lmul_left_mul }

end

end algebra

namespace submodule
open algebra

variables {R : Type*} [comm_ring R]

section
variables {A : Type*} [ring A] [algebra R A]
variables {B : Type*} [ring B] [algebra R B]
variables (f : A →ₐ[R] B)
variables (M N : submodule R A)

attribute [simp] comap_id

lemma map_mul : (M * N).map f.to_linear_map = M.map f.to_linear_map * N.map f.to_linear_map :=
begin
  apply le_antisymm,
  { rw [map_le_iff_le_comap, mul_le],
    intros,
    erw [mem_comap, f.map_mul],
    apply mul_mem_mul; refine ⟨_, ‹_›, rfl⟩ },
  { rw mul_le,
    rintros _ ⟨m, hm, rfl⟩ _ ⟨n, hn, rfl⟩,
    use [m * n, mul_mem_mul hm hn],
    apply f.map_mul }
end

@[simp] lemma lmul_left_one : lmul_left R A 1 = linear_map.id :=
linear_map.ext $ λ _, one_mul _

lemma lmul_left_comp (a : A) :
  f.to_linear_map.comp (lmul_left R A a) = (lmul_left R B (f a)).comp f.to_linear_map :=
linear_map.ext $ λ b, f.map_mul a b

lemma map_eq_comap_symm {M : Type*} {N : Type*}
  [add_comm_group M] [add_comm_group N] [module R M] [module R N]
  (f : M ≃ₗ[R] N) :
  map (↑f : M →ₗ[R] N) = comap ↑f.symm :=
funext $ λ P, ext $ λ x,
begin
  rw [mem_map, mem_comap],
  split; intro h,
  { rcases h with ⟨p, h₁, h₂⟩,
    erw ← f.to_equiv.eq_symm_apply at h₂,
    rwa h₂ at h₁ },
  { exact ⟨_, h, f.apply_symm_apply x⟩ }
end

def linear_equiv_of_units {M : Type*} [add_comm_group M] [module R M]
  (f : units (M →ₗ[R] M)) : (M ≃ₗ[R] M) :=
{ inv_fun := f.inv.to_fun,
  left_inv := λ m, show (f.inv * f.val) m = m,
    by erw f.inv_val; simp,
  right_inv := λ m, show (f.val * f.inv) m = m,
    by erw f.val_inv; simp,
  ..f.val }

def units_of_linear_equiv {M : Type*} [add_comm_group M] [module R M]
  (f : (M ≃ₗ[R] M)) : units (M →ₗ[R] M) :=
{ val := f,
  inv := f.symm,
  val_inv := linear_map.ext $ λ _, f.apply_symm_apply _,
  inv_val := linear_map.ext $ λ _, f.symm_apply_apply _ }

def units_equiv {M : Type*} [add_comm_group M] [module R M] :
  units (M →ₗ[R] M) ≃ (M ≃ₗ[R] M) :=
{ to_fun := linear_equiv_of_units,
  inv_fun := units_of_linear_equiv,
  left_inv := by tidy,
  right_inv := λ f,
  begin
    delta linear_equiv_of_units units_of_linear_equiv,
    cases f,
    tidy
  end }

lemma map_lmul_left_inv (a : units A) :
  map (lmul_left R A ↑a⁻¹) = comap (lmul_left R A a) :=
map_eq_comap_symm $ linear_equiv_of_units $
  units.map (lmul_left R A) a⁻¹

lemma lmul_left_units_le_iff (a : units A) :
  M.map (lmul_left _ _ a) ≤ N ↔ M ≤ N.map (lmul_left _ _ ↑a⁻¹) :=
by rw [map_le_iff_le_comap, map_lmul_left_inv]

end

end submodule
