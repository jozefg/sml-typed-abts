functor Symbol () :> SYMBOL =
struct
  type t = int * string
  val counter = ref 0

  fun named a =
    let
      val i = !counter
      val _ = counter := i + 1
    in
      (i, a)
    end

  fun new () =
    named "@"

  fun compare ((i, _), (j, _)) =
    Int.compare (i, j)

  structure Eq =
  struct
    type t = t
    fun eq ((i : int, _), (j, _)) = i = j
  end

  fun clone (_, a) =
    named a

  structure Show =
  struct
    type t = t
    fun toString (_, a) = a
  end

  structure DebugShow =
  struct
    type t = t
    fun toString (i, a) =
      a ^ "@" ^ Int.toString i
  end
end

structure StringPresymbol : PRESYMBOL =
struct
  type t = string
  fun named x = x

  structure Show =
  struct
    type t = t
    fun toString x = x
  end

  structure Eq =
  struct
    type t = t
    fun eq (x, y) = x = y
  end

  val compare = String.compare
end
